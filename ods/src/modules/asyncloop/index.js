export const asyncForEach = async (array, callback) => {
  const retArray = []
  for (let index = 0; index < array.length; ) {
    const resp = await callback(array[index], index, array)
    retArray.push(resp)
    index += 1
  }
  return retArray
}
