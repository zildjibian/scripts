from socket import gethostname, gethostbyname
import asyncio
import websockets

ipv4 = gethostbyname(gethostname())
port = 8765

async def handler(websocket, path):
    print(path + ":")
    async for message in websocket:
        print("-", message)
    # await websocket.send(content: str) to send to RBLX

print('Starting Server...')

server = websockets.serve(handler, ipv4, port)

print("Running on ws://" + ipv4 + ":" + str(port))

asyncio.get_event_loop().run_until_complete(server)
asyncio.get_event_loop().run_forever()
