OX Inventory item setup:

Add this to ox_inventory/data/items.lua:

['crafting_bench'] = {
    label = 'Crafting Bench',
    weight = 10000,
    stack = false,
    consume = 1,
    client = {
        event = 'bench:useItem'
    }
}

SQL:

CREATE TABLE IF NOT EXISTS placed_benches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    x DOUBLE,
    y DOUBLE,
    z DOUBLE,
    heading DOUBLE
);
