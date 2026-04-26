let _ref = null;

export function _setToastRef(ref) {
  _ref = ref;
}

function add(type, content) {
  if (!_ref) return;
  if (typeof content === 'object' && content !== null) {
    _ref.add({ type, title: content.title, message: content.message, duration: content.duration });
  } else {
    _ref.add({ type, message: String(content) });
  }
}

export const toast = {
  success: (content) => add('success', content),
  error:   (content) => add('error',   content),
  warning: (content) => add('warning', content),
  info:    (content) => add('info',    content),
};
