const localConfig = require('./local-email-config.js')
const realConfig = require('test-common/real-email-config')

const stage = process.env.SLIC_STAGE
export function getBaseURL() {
  let url
  const domainSuffix = stage === 'prod' ? '' : `${stage}.`

  if (stage === 'local') {
    url = 'http://localhost:3000'
  } else {
    const nsDomain = process.env.SLIC_NS_DOMAIN
    if (!nsDomain) {
      throw new Error('SLIC_NS_DOMAIN must be set')
    }
    url = `https://${domainSuffix}${nsDomain}`
  }

  return url
}

export function getEmail() {
  let config
  let email
  if (stage === 'local') {
    config = localConfig
  } else {
    config = realConfig
  }

  email = config.generateEmailAddress()
  return email
}

export function getCode(email) {
  switch (stage) {
    case 'local':
      return localConfig.retrieveCode(email)

    default:
      return realConfig.retrieveCode(email).then(result => {
        return result
      })
  }
}
