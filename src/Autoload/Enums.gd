extends Node

# Language options for dialogue boxes and button texts
enum Languages { CZ, EN, UNDEFINED }

# Possible effects distributed to GameActor classes
enum Effects { DAMAGE, PUSH, MINERALS, ADD_CONSTANT_PUSH, REMOVE_CONSTANT_PUSH }

# Event requests
enum Events { SHAKE_BIG, SHAKE_MEDIUM, SHAKE_SMALL }
