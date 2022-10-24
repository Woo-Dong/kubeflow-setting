# pip install passlib bcrpyt

from passlib.hash import bcrypt
import getpass

print(bcrypt.using(rounds=12, ident="2y").hash(getpass.getpass()))
