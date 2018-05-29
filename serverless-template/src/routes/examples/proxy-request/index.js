import ware from 'warewolf'
import fetch from 'node-fetch'
import { before, after } from '../../../utils'

export const proxy = ware(
  before,

  async (event) => {
    const { acronym } = event.params

    await fetch(`http://www.nactem.ac.uk/software/acromine/dictionary.py?sf=${acronym}`, {
      headers: {
        Accept: 'text/plain',
        'Content-type': 'application/json',
      },
      method: 'GET',
    })
      .then(response => response.json())
      .then((result) => {
        event.result = formatAcronymResult(result)
      })
      .catch((error) => {
        event.error = error
      })
  },

  after,
)

const formatAcronymResult = (acronymAPIResult) => {
  if (!acronymAPIResult || acronymAPIResult == null || !(acronymAPIResult.length > 0)) {
    return {}
  }

  const input = acronymAPIResult[0].sf
  const acronyms = acronymAPIResult[0].lfs.map(acronym => acronym.lf)

  return {
    input,
    acronyms,
  }
}
