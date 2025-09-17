# pragma version 0.4.3
# @license MIT

import favorites
initializes: favorites
exports: (favorites.retrieve)

@deploy
def __init__():
    favorites.__init__()


@external
def store(favorite_number: uint256):
    favorites.my_favorite_number = favorite_number + 5
