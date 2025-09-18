from script.deploy import deploy
import pytest

@pytest.fixture
def deployed_contract():
    return deploy()