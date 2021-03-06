import _ from 'lodash'
import { ODSArchive } from './ods-archive'
import { getAndSetVarsFromEnvFile } from '../../../env'

const event = require('./event.json')

describe('ODS Archive - Unit Tests', () => {
  it.skip('ODS Archive - Get Completed Tasks', async () => {
    getAndSetVarsFromEnvFile(false)
    try {
      const objArch = new ODSArchive(event)
      expect.assertions(3)
      const cTasks = await objArch.GetCompletedTasks()
      // console.log(`Completed Tasks: ${JSON.stringify(cTasks, null, 2)}`)
      expect(cTasks).toBeDefined()
      expect(_.isArray(cTasks)).toBe(true)
      expect(_.size(cTasks)).toBeGreaterThan(0)
    } catch (err) {
      console.log('error', err.message)
      expect(err).toBeUndefined()
    }
  })
  it.skip('ODS Archive - Get Completed Tasks to Archive', async () => {
    getAndSetVarsFromEnvFile(false)
    try {
      const objArch = new ODSArchive(event)
      const cTasks = await objArch.GetCompletedTasks()
      expect.assertions(3)
      const archTasks = await objArch.GetTasksToArchive(cTasks)
      // console.log(`Tasks to Archive: ${JSON.stringify(archTasks, null, 2)}`)
      expect(archTasks).toBeDefined()
      expect(_.isArray(archTasks)).toBe(true)
      expect(_.size(archTasks)).toBeGreaterThan(0)
    } catch (err) {
      console.log('error', err.message)
      expect(err).toBeUndefined()
    }
  })
  it.skip('ODS Archive - Get Completed Task Attributes to Archive', async () => {
    getAndSetVarsFromEnvFile(false)
    try {
      const objArch = new ODSArchive(event)
      const cTasks = await objArch.GetCompletedTasks()
      expect.assertions(3)
      const archAttributes = await objArch.GetAttributesToArchive(cTasks)
      // console.log(`Attributes to Archive: ${JSON.stringify(archAttributes, null, 2)}`)
      expect(archAttributes).toBeDefined()
      expect(_.isArray(archAttributes)).toBe(true)
      expect(_.size(archAttributes)).toBeGreaterThan(0)
    } catch (err) {
      console.log('error', err.message)
      expect(err).toBeUndefined()
    }
  })
  it.skip('ODS Archive - Save to Archive DB', async () => {
    getAndSetVarsFromEnvFile(false)
    try {
      const objArch = new ODSArchive(event)
      const cTasks = await objArch.GetCompletedTasks()
      const archTasks = await objArch.GetTasksToArchive(cTasks)
      const archAttributes = await objArch.GetAttributesToArchive(cTasks)
      let totalCount = _.size(archTasks) + _.size(archAttributes)
      expect.assertions(4)
      const saveResp = await objArch.ArchiveTasksAndAttributes(archTasks, archAttributes)
      console.log(`Counts: ${_.size(saveResp)}, expected: ${totalCount}`)
      expect(saveResp).toBeDefined()
      expect(_.isArray(saveResp)).toBe(true)
      expect(_.size(saveResp)).toBeGreaterThan(0)
      expect(_.size(saveResp)).toBe(totalCount)
    } catch (err) {
      console.log('error', err.message)
      expect(err).toBeUndefined()
    }
  })
  it.only('ODS Archive - Entire Archive Process', async () => {
    getAndSetVarsFromEnvFile(false)
    try {
      const objArch = new ODSArchive(event)
      expect.assertions(1)
      const archResp = await objArch.ArchiveTasksAndFiles()
      console.log(`archResp: ${JSON.stringify(archResp, null, 2)}`)
      expect(archResp).toBeDefined()
    } catch (err) {
      console.log('error', err.message)
      expect(err).toBeUndefined()
    }
  })
})
