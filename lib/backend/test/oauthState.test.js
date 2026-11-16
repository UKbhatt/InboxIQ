const test = require('node:test');
const assert = require('node:assert/strict');

process.env.ENCRYPTION_KEY = 'a'.repeat(64);
const { createState, verifyState, STATE_TTL_MS } = require('../utils/oauthState');

const USER_ID = '2f6d8a9e-1f2a-4c3b-9d8e-7a6b5c4d3e2f';

test('a freshly created state verifies back to the same user id', () => {
  const state = createState(USER_ID, 1000);
  assert.equal(verifyState(state, 1000), USER_ID);
});

test('a raw user id without a signature is rejected', () => {
  assert.equal(verifyState(USER_ID), null);
});

test('a state whose user id was swapped is rejected', () => {
  const state = createState(USER_ID, 1000);
  const tampered = state.replace(USER_ID, 'attacker-controlled-id');
  assert.equal(verifyState(tampered, 1000), null);
});

test('a state past its expiry is rejected', () => {
  const state = createState(USER_ID, 1000);
  assert.equal(verifyState(state, 1000 + STATE_TTL_MS + 1), null);
});

test('a state signed with a different key is rejected', () => {
  const state = createState(USER_ID, 1000);
  process.env.ENCRYPTION_KEY = 'b'.repeat(64);
  assert.equal(verifyState(state, 1000), null);
  process.env.ENCRYPTION_KEY = 'a'.repeat(64);
});
