export const asyncForEach = async (array, callback) => {
    retArray = new Array;
    for (let index = 0; index < array.length; index++) {
        let resp = await callback(array[index], index, array);
        retArray.push(resp);
    }
    return retArray;
}