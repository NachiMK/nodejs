import { parseSchemaJSON } from './generate-json-schema'

const testJSON = {
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "persons-complex-single",
  "type": "object",
  "properties": {
    "Id": {
      "type": "number"
    },
    "FirstName": {
      "type": "string"
    },
    "LastName": {
      "type": "string"
    },
    "Gender": {
      "type": "string"
    },
    "DateOfBirth": {
      "type": "string",
      "format": "date"
    },
    "IsActive": {
      "type": "boolean"
    },
    "Salary": {
      "type": [
        "number",
        "null"
      ]
    },
    "PhoneNumber": {
      "type": [
        "number",
        "string"
      ]
    },
    "Spouse": {
      "type": "object",
      "properties": {
        "Id": {
          "type": "number"
        },
        "SpouseName": {
          "type": "string"
        },
        "SpouseDOB": {
          "type": "string",
          "format": "date"
        }
      }
    },
    "Children": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "Benefits": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "Id": {
            "type": "number"
          },
          "BenefitType": {
            "type": "string"
          },
          "BenefitName": {
            "type": "string"
          },
          "EffectiveDate": {
            "type": "string",
            "format": "date"
          },
          "CoveredBenefits": {
            "type": "array",
            "items": {
              "type": "string"
            }
          },
          "Provider": {
            "type": "object",
            "properties": {
              "Id": {
                "type": "number"
              },
              "Name": {
                "type": "string"
              },
              "ERLocations": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              }
            }
          },
          "IsActive": {
            "type": "string"
          }
        },
        "required": [
          "Id",
          "BenefitType",
          "BenefitName",
          "EffectiveDate",
          "CoveredBenefits",
          "Provider",
          "IsActive"
        ]
      }
    }
  }
}


const testOutput = {
	"Id": {
		"type": "number",
		"default": -999999.99,
		"transfer_type": "string",
		"db_type": "number"
	},
	"FirstName": {
		"type": "string",
		"default": "",
		"transfer_type": "string",
		"db_type": "string"
	},
	"LastName": {
		"type": "string",
		"default": "",
		"transfer_type": "string",
		"db_type": "string"
	},
	"Gender": {
		"type": "string",
		"default": "",
		"transfer_type": "string",
		"db_type": "string"
	},
	"DateOfBirth": {
		"type": "string",
		"default": "",
		"transfer_type": "string",
		"db_type": "date"
	},
	"IsActive": {
		"type": "boolean",
		"default": false,
		"transfer_type": "string",
		"db_type": "boolean"
	},
	"Salary": {
		"type": "number",
		"default": -999999.99,
		"transfer_type": "string",
		"db_type": "number"
	},
	"PhoneNumber": {
		"type": "string",
		"default": "",
		"transfer_type": "string",
		"db_type": "string"
	},
	"Spouse": {
		"type": "object",
		"properties": {
			"Id": {
				"type": "number",
				"default": -999999.99,
				"transfer_type": "string",
				"db_type": "number"
			},
			"SpouseName": {
				"type": "string",
				"default": "",
				"transfer_type": "string",
				"db_type": "string"
			},
			"SpouseDOB": {
				"type": "string",
				"default": "",
				"transfer_type": "string",
				"db_type": "date"
			}
		}
	},
	"Children": {
		"type": "array",
		"items": {
			"type": "string"
		}
	},
	"Benefits": {
		"type": "array",
		"items": {
			"type": "object",
			"properties": {
				"Id": {
					"type": "number",
					"default": -999999.99,
					"transfer_type": "string",
					"db_type": "number"
				},
				"BenefitType": {
					"type": "string",
					"default": "",
					"transfer_type": "string",
					"db_type": "string"
				},
				"BenefitName": {
					"type": "string",
					"default": "",
					"transfer_type": "string",
					"db_type": "string"
				},
				"EffectiveDate": {
					"type": "string",
					"default": "",
					"transfer_type": "string",
					"db_type": "date"
				},
				"CoveredBenefits": {
					"type": "array",
					"items": {
						"type": "string"
					}
				},
				"Provider": {
					"type": "object",
					"properties": {
						"Id": {
							"type": "number",
							"default": -999999.99,
							"transfer_type": "string",
							"db_type": "number"
						},
						"Name": {
							"type": "string",
							"default": "",
							"transfer_type": "string",
							"db_type": "string"
						},
						"ERLocations": {
							"type": "array",
							"items": {
								"type": "string"
							}
						}
					}
				},
				"IsActive": {
					"type": "string",
					"default": "",
					"transfer_type": "string",
					"db_type": "string"
				}
			},
			"required": ["Id", "BenefitType", "BenefitName", "EffectiveDate", "CoveredBenefits", "Provider", "IsActive"]
		}
	}
}

describe('parseSchemaJSON', () => {
  describe('person schema - complex', () => {
    const output = parseSchemaJSON(testJSON.properties)

    // Person Id
    it('should set Person Id type', () => {
      expect(output.Id.type).toBe(testOutput.Id.type)
    })
    it('should set Person Id default value', () => {
      expect(output.Id.default).toBe(testOutput.Id.default)
    })
    it('should set Person Id transfer type', () => {
      expect(output.Id.transfer_type).toBe(testOutput.Id.transfer_type)
    })
    it('should set Person Id db type', () => {
      expect(output.Id.db_type).toBe(testOutput.Id.db_type)
    })

    // Person FirstName
    it('should set Person FirstName type', () => {
      expect(output.FirstName.type).toBe(testOutput.FirstName.type)
    })
    it('should set Person FirstName default value', () => {
      expect(output.FirstName.default).toBe(testOutput.FirstName.default)
    })
    it('should set Person FirstName transfer type', () => {
      expect(output.FirstName.transfer_type).toBe(testOutput.FirstName.transfer_type)
    })
    it('should set Person FirstName db type', () => {
      expect(output.FirstName.db_type).toBe(testOutput.FirstName.db_type)
    })

    // Person Children
    it('should set Person Children type', () => {
      expect(output.Children.type).toBe(testOutput.Children.type)
    })
    it('should set Person Children items type', () => {
      expect(output.Children.items.type).toBe(testOutput.Children.items.type)
    })
    it('should have only 2 keys for Person Children', () => {
      expect(Object.keys(output.Children).length).toBe(2)
    })
  })
})
