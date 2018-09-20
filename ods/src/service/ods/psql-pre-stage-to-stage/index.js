import odsLogger from '../../../modules/log/ODSLogger'
import { TaskStatusEnum } from '../../../modules/ODSConstants'

export async function DoTaskPreStageToStage(dataPipeLineTaskQueue) {
  const taskResp = {}
  taskResp.Status = TaskStatusEnum.OnHold
  // let input
  return taskResp
}
