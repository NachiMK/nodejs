import ware from 'warewolf';
import fetch from 'node-fetch';
import { before, after } from '@hixme/before-after-middleware';

export const proxy = ware(
  before,
  async (event) => {
    const { acronym } = event.params;

    const response = await fetch(`http://www.nactem.ac.uk/software/acromine/dictionary.py?sf=${acronym}`, {
      headers: {
        Accept: 'text/plain',
        'Content-type': 'application/json',
      },
      method: 'GET',
    });
    const json = response.json();
    event.response = formatAcronymResult(json);
  },
  after,
);

const formatAcronymResult = (acronymAPIResult) => {
  if (!acronymAPIResult || acronymAPIResult == null || !(acronymAPIResult.length > 0)) {
    return {};
  }

  const input = acronymAPIResult[0].sf;
  const acronyms = acronymAPIResult[0].lfs.map(acronym => acronym.lf);

  return {
    input,
    acronyms,
  };
};
