import os
import sys

# Dynamically inject the repository root into the systemic search path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))
