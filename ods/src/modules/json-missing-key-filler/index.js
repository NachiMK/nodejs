import { format as _format, transports as _transports, createLogger } from 'winston';
import _isEmpty from 'lodash/isEmpty';
import { GetJSONFromS3Path, SaveJsonToS3File } from '../s3ODS';
import { ExtractMatchingKeyFromSchema } from '../json-extract-matching-keys/index';

const fillMissingKeys = require('object-fill-missing-keys');

export class JsonMissingKeyFiller {
  output = {
    status: {
      message: 'processing',
    },
    error: undefined,
    S3UniformJsonFile: undefined,
    UniformJsonData: undefined,
  };
  defaultSchema = undefined;
  logger = createLogger({
    format: _format.combine(
      _format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss',
      }),
      _format.splat(),
      _format.prettyPrint(),
    ),
  });

  constructor(params = {}) {
    this.s3SchemaFile = params.S3SchemaFile || '';
    this.s3DataFile = params.S3DataFile || '';
    this.s3OutputBucket = params.S3OutputBucket || '';
    this.s3OutputKey = params.S3OutputKey || '';
    this.loglevel = params.LogLevel || 'warn';
    this.consoleTransport = new _transports.Console();
    this.consoleTransport.level = params.LogLevel;
    this.logger.add(this.consoleTransport);
  }
  get S3SchemaFile() {
    return this.s3SchemaFile;
  }
  get S3DataFile() {
    return this.s3DataFile;
  }
  get ModuleError() {
    return this.output.error;
  }
  get ModuleStatus() {
    return this.output.status.message;
  }
  get Output() {
    return this.output;
  }
  get S3UniformJsonFile() {
    return this.output.S3UniformJsonFile;
  }
  get LogLevel() {
    return this.loglevel;
  }
  get DefaultSchema() {
    return this.defaultSchema;
  }
  get S3OutputBucket() {
    return this.s3OutputBucket;
  }
  get S3OutputKey() {
    return this.s3OutputKey;
  }
  ValidateParams() {
    if (_isEmpty(this.S3SchemaFile)) {
      throw new Error('Invalid Param. Please pass a S3SchemaFile');
    }
    if (_isEmpty(this.S3DataFile)) {
      throw new Error('Invalid Param. Please pass valid S3 Data File');
    }
  }
  async getUniformJsonData() {
    try {
      this.ValidateParams();
      const schemaFromS3 = await GetJSONFromS3Path(this.S3SchemaFile);
      const dataFromS3 = await GetJSONFromS3Path(this.S3DataFile);

      if (!(schemaFromS3) || !(dataFromS3)) {
        throw new Error(`No data in Schema File: ${this.S3SchemaFile} or in Data File: ${this.S3DataFile}`);
      }

      this.defaultSchema = ExtractMatchingKeyFromSchema(schemaFromS3, null, 'default');
      this.logger.log('debug', '---------------- DEFAULT SCHEMA ----------');
      this.logger.log('debug', JSON.stringify(this.DefaultSchema, null, 2));
      this.logger.log('debug', '---------------- DEFAULT SCHEMA ----------');

      if (!this.DefaultSchema) {
        throw new Error(`Default Schema from File: ${schemaFromS3} couldn't be extracted`);
      }

      this.AddMissingKeys(dataFromS3);
      if (this.S3OutputBucket && this.S3OutputKey &&
          this.S3OutputBucket.length > 0 && this.S3OutputKey.length > 0) {
        this.Output.S3UniformJsonFile = await SaveJsonToS3File(`s3://${this.S3OutputBucket}/${this.S3OutputKey}`, this.Output.UniformJsonData);
        // clear output if saving to s3
        this.Output.UniformJsonData = undefined;
      }
      this.Output.status.message = 'success';
    } catch (err) {
      console.log(`Error in JsonDataNormalier: ${JSON.stringify(err.message, null, 2)}`);
      this.Output.status.message = 'error';
      this.Output.error = err;
    }
  }

  AddMissingKeys = (dataRows) => {
    if (dataRows) {
      this.Output.UniformJsonData = dataRows.map((item) => {
        if (item.Item) return this.Filldefaults(item.Item, this.DefaultSchema);
        return this.Filldefaults(item, this.DefaultSchema);
      });
    }
    this.logger.log('debug', '---------------- FILLED ROWS ----------');
    this.logger.log('debug', JSON.stringify(this.Output.UniformJsonData, null, 2));
    this.logger.log('debug', '---------------- FILLED ROWS ----------');
  };

  Filldefaults(dataRow) {
    const result = fillMissingKeys(
      dataRow,
      this.DefaultSchema,
    );
    this.DeleteNullObjectsArrays(result);
    return result;
  }

  DeleteNullObjectsArrays(jsonRow) {
    if (jsonRow instanceof Object) {
      this.logger.log('debug', 'Deleting Null elements');
      Object.keys(jsonRow).forEach((prop) => {
        if (JSON.stringify(jsonRow[prop]).localeCompare('null') === 0) {
          delete jsonRow[prop];
        }
      });
    }
  }
}
