export const baseRoutes = {
  create: {
    method: 'POST',
    path: '',
    config: {
      payload: { output: 'data', parse: true },
    },
  },
  read: {
    method: 'GET',
    path: '/{itemId}',
  },
  update: {
    method: 'PATCH',
    path: '/{itemId}',
    config: {
      payload: { output: 'data', parse: true },
    },
  },
  destroy: {
    method: 'DELETE',
    path: '/{itemId}',
  },
};
