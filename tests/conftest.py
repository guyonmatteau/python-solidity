# this implements some logic such we can pass the address to which the contract 
# will be deployed can be passed and consumed to multiple tests
import pytest

class Deployment:
    address: str
    account: str


def pytest_configure():
    pytest.deployment = Deployment()


