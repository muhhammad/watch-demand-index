import unittest

from api.auth import hash_password, verify_password


class PasswordHashingTests(unittest.TestCase):
    def test_hash_and_verify_password(self) -> None:
        hashed = hash_password("TestPass123!")

        self.assertNotEqual(hashed, "TestPass123!")
        self.assertTrue(hashed.startswith("$2"))
        self.assertTrue(verify_password("TestPass123!", hashed))


if __name__ == "__main__":
    unittest.main()
