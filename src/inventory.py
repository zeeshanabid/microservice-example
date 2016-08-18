import asyncio
import uuid
import json
from nats.aio.client import Client as NATS
from nats.aio.errors import ErrConnectionClosed, ErrTimeout, ErrNoServers

QUEUE_GROUP = "inventory-service"
WORKER_ID = uuid.uuid4()

def to_json(o):
    return o.__dict__

class Stock:
    def __init__(self, product_id, stock=0):
        self.product_id = product_id
        self.stock = stock

    def __repr__(self):
        return 'Stock(id:{}, stock:{})'.format(self.product_id, self.stock)

class InventoryController:
    def __init__(self):
        self.inventory = {}

    def add_stock(self, product_id, stock):
        inventory = self.inventory.get(product_id, Stock(product_id))
        inventory.stock += stock
        self.inventory[product_id] = inventory

    def remove_stock(self, product_id, stock):
        inventory = self.inventory[product_id]
        inventory.stock -= stock
        self.inventory[product_id] = inventory

    def get_stock(self, product_id):
        return self.inventory[product_id]

inventory_controller = InventoryController()

def run(loop):
    nc = NATS()
    yield from nc.connect(io_loop=loop)

    def msg_data(msg):
        return msg.subject, msg.reply, json.loads(msg.data.decode())

    @asyncio.coroutine
    def add_stock(msg):
        subject, reply, data = msg_data(msg)
        print('Add stock at worker: {}'.format(WORKER_ID))
        inventory_controller.add_stock(data['product_id'], data.get('stock', 1))
        if reply:
            yield from nc.publish(reply, json.dumps({'msg': 'Stock added'}).encode())

    @asyncio.coroutine
    def remove_stock(msg):
        try:
            subject, reply, data = msg_data(msg)
            print('Remove stock at worker: {}'.format(WORKER_ID))
            inventory_controller.remove_stock(data['product_id'], data.get('stock', 1))
            if reply:
                yield from nc.publish(reply, json.dumps({'msg': 'Stock removed'}).encode())
        except KeyError as e:
            print('Cannot find the product_id or product_id not present in the request', e)

    @asyncio.coroutine
    def get_stock(msg):
        try:
            subject, reply, data = msg_data(msg)
            print('Get stock at worker: {}'.format(WORKER_ID))
            stock = inventory_controller.get_stock(data['product_id'])
            yield from nc.publish(reply, json.dumps(stock, default=to_json).encode())
        except Exception as e:
            print('Cannot find the product_id or product_id not present in the request', e)

    # Simple async subscriber via coroutine.
    yield from nc.subscribe('stock.add', queue=QUEUE_GROUP, cb=add_stock)
    yield from nc.subscribe('stock.remove', queue=QUEUE_GROUP, cb=remove_stock)
    yield from nc.subscribe('stock.get', queue=QUEUE_GROUP, cb=get_stock)
    print('Worker started for "{}" queue with id: {}'.format(QUEUE_GROUP, WORKER_ID))


if __name__ == '__main__':
    loop = asyncio.get_event_loop()
    loop.run_until_complete(run(loop))
    try:
        loop.run_forever()
    finally:
        loop.close()
