import odsLogger from '../../../modules/log/ODSLogger'
import { TaskStatusEnum } from '../../../modules/ODSConstants'

export async function DoTaskStageToClean(dataPipeLineTaskQueue) {
  const taskResp = {}
  taskResp.Status = TaskStatusEnum.OnHold.name
  // let input
  return taskResp
}
