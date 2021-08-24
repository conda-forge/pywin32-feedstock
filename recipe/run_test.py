"""
Full module list obtained from: http://timgolden.me.uk/pywin32-docs/win32_modules.html

Skipped modules:

_winxptheme: private module
wincerapi: interface to the win32 CE Remote API
"""
import os
import sys

IS_PYPY = sys.implementation.name == 'pypy'

import mmapfile
import odbc
import perfmon
import pywintypes
import timer
import win32ras
import win32api
import win32clipboard
import win32console
import win32cred
import win32crypt
import win32event
import win32evtlog
import win32file
import win32gui
import win32help
import win32inet
import win32job
import win32lz
import win32net
import win32pdh
import win32pipe
import win32print
import win32process
import win32profile
import win32security
import win32service
import win32transaction
import win32ts
import win32wnet
if IS_PYPY:
    try:
        import servicemanager
        import win32ui
        import win2kras
    except ImportError:
        pass
    else:
        raise ImportError('sucesssfully imported module that should not be importable')
else:
    import servicemanager
    import win32ui

conda_py = str(os.sys.version_info.major) + str(os.sys.version_info.minor)

pythoncom_filename = os.environ["LIBRARY_BIN"] + "\pythoncom" + conda_py + ".dll"
pywintypes_filename = os.environ["LIBRARY_BIN"] + "\pywintypes" + conda_py + ".dll"

if not IS_PYPY:
    assert os.path.isfile(pythoncom_filename)
assert os.path.isfile(pywintypes_filename)
