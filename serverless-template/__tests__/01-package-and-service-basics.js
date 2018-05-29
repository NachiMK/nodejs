import pkg from '../package.json'

describe('Project Package and Service Basics', () => {
  it('\'package.json\' file exists', () => {
    expect(pkg).toBeDefined()
  })

  it('\'package.json\' contains keys', () => {
    expect(Reflect.ownKeys(pkg).length).toBeGreaterThan(0)
  })

  it('\'package.json\' contains values', () => {
    Object.keys(pkg).forEach((key) => {
      expect(pkg[key]).toBeDefined()
    })
  })

  it('\'package.json\' contains all _required_ keys', () => {
    const REQUIRED_PACKAGE_KEYS = [
      'name',
      'version',
      'description',
      'main',
      'scripts',
      'repository',
      'dependencies',
      'devDependencies',
    ]

    expect(Reflect.ownKeys(pkg)).toEqual(expect.arrayContaining(REQUIRED_PACKAGE_KEYS))
  })
})
