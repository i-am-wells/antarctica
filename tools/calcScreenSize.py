
from sys import argv

def calcScreenSize(sw, sh):
    targetW = 456
    targetH = 256

    factorX = sw / targetW
    factorY = sh / targetH

    print(factorX, factorY)
    print(max(factorX, factorY) // 1 + 1)

if __name__=='__main__':
    calcScreenSize(int(argv[1]), int(argv[2]))
