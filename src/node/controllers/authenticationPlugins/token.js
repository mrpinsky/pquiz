import crypto from 'crypto';

import { services } from '../../services';
import { User } from '../../models/user';

const store = {
  aa: 1,
};

function tokenToUser(token) {
  const maybeUser = store[token];
  if (typeof maybeUser === 'number') {
    return services.knex('users').where({ id: maybeUser }).select()
    .then(l => l[0]);
  } else {
    const user = {};
    for (const field in maybeUser) {
      if (field in User.$fields) {
        user[field] = maybeUser[field];
      }
    }
    return Promise.resolve(user);
  }
}

function addUser(userData, token) {
  const tokenKey = token || crypto.randomBytes(24).toString('hex');
  store[tokenKey] = new User(userData);
  return tokenKey;
}

export const TokenStrategy = {
  strategy: {
    validateFunc: (token, callback) => {
      return tokenToUser(token)
      .then(user => {
        if (user !== null) {
          return callback(null, true, { user: user });
        } else {
          return callback(null, false);
        }
      })
      .catch(err => callback(err));
    },
    allowQueryToken: false,
  },
  getUser: tokenToUser,
  addUser: addUser,
};
