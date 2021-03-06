'use strict'

const checklist = require('./checklist')
const { processEvent } = require('slic-tools/event-util')

async function main(event) {
  const { pathParameters, userId } = processEvent(event)
  const { id: listId } = pathParameters
  return checklist.listCollaborators({ listId, userId })
}

module.exports = {
  main
}
