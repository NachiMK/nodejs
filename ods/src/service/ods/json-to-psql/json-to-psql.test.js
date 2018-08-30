import { JsonToPSQL } from '.'
import { getAndSetVarsFromEnvFile } from '../../../../env'

const event = require('./event.json')
console.log(`stage:${process.env.STAGE}, STAGE: ${process.env.STAGE}`)
getAndSetVarsFromEnvFile(false)

describe('JsonToPSQL - Process one or Zero tasks successfully', () => {
  it('should Process one or Zero tasks successfully', async () => {
    const { Status, TasksToProcess, RemainingTasks, error } = await JsonToPSQL(event)
    if (TasksToProcess > 0) {
      expect(Status).toBe('success')
      expect(RemainingTasks).toBeLessThanOrEqual(3)
      expect(error).toBeUndefined()
    } else {
      expect(Status).toBe('warning')
      expect(RemainingTasks).toBe(0)
      expect(error).toBeUndefined()
    }
  })
})
