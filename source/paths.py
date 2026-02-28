import os

SOURCE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SOURCE_DIR)
CRASH_LOG_PATH = os.path.join(PROJECT_DIR, "crash.log")


def project_path(*parts):
    return os.path.join(PROJECT_DIR, *parts)


def source_path(*parts):
    return os.path.join(SOURCE_DIR, *parts)


def ensure_project_cwd():
    if os.getcwd() != PROJECT_DIR:
        os.chdir(PROJECT_DIR)
