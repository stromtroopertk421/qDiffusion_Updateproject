"""QML registration helpers with cross-binding compatibility."""

# Prefer modern singleton-instance registration where available.
# Keep a callback-based fallback for bindings/runtime combos that do not expose it.

_qml_register_singleton_instance = None
_qml_register_singleton_type = None

try:
    from PySide6.QtQml import qmlRegisterSingletonInstance as _qml_register_singleton_instance
    from PySide6.QtQml import qmlRegisterSingletonType as _qml_register_singleton_type
except ImportError:  # pragma: no cover - fallback bindings
    try:
        from PyQt6.QtQml import qmlRegisterSingletonInstance as _qml_register_singleton_instance
        from PyQt6.QtQml import qmlRegisterSingletonType as _qml_register_singleton_type
    except ImportError:  # pragma: no cover - fallback bindings
        try:
            from PyQt5.QtQml import qmlRegisterSingletonType as _qml_register_singleton_type
        except ImportError as exc:  # pragma: no cover - fail loudly if no Qt binding exists
            raise ImportError("No supported Qt QML binding found") from exc


def register_qml_singleton(qobject_type, uri, major_version, minor_version, qml_name, instance):
    """Register an existing Python object as a QML singleton.

    Uses qmlRegisterSingletonInstance when available (Qt >= 5.14).
    Falls back to callback-based qmlRegisterSingletonType for older bindings.
    """
    if _qml_register_singleton_instance is not None:
        return _qml_register_singleton_instance(
            qobject_type,
            uri,
            major_version,
            minor_version,
            qml_name,
            instance,
        )

    def _singleton_factory(*_args):
        return instance

    return _qml_register_singleton_type(
        qobject_type,
        uri,
        major_version,
        minor_version,
        qml_name,
        _singleton_factory,
    )
