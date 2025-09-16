from script.deploy import deploy_favorites
import pytest

@pytest.fixture
def favorites_contract():
    return deploy_favorites()