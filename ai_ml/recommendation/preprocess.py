from pathlib import Path
import pandas as pd


# ---------------------------------------------------------
# SmartKart AI - Recommendation Data Preprocessing
# ---------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[2]

DATA_DIR = PROJECT_ROOT / "datasets" / "instacart" / "raw"
OUTPUT_DIR = PROJECT_ROOT / "datasets" / "processed"

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


PRODUCTS_FILE = DATA_DIR / "products.csv"
AISLES_FILE = DATA_DIR / "aisles.csv"
DEPARTMENTS_FILE = DATA_DIR / "departments.csv"
ORDERS_FILE = DATA_DIR / "orders.csv"
ORDER_PRODUCTS_FILE = DATA_DIR / "order_products__prior.csv"


def load_product_catalog():
    """Load product, aisle and department information."""

    products = pd.read_csv(PRODUCTS_FILE)
    aisles = pd.read_csv(AISLES_FILE)
    departments = pd.read_csv(DEPARTMENTS_FILE)

    products = products.merge(
        aisles,
        on="aisle_id",
        how="left"
    )

    products = products.merge(
        departments,
        on="department_id",
        how="left"
    )

    products = products.rename(
        columns={
            "product_id": "product_id",
            "product_name": "product_name",
            "aisle": "aisle_name",
            "department": "department_name"
        }
    )

    return products


def load_orders():
    """Load customer order information."""

    orders = pd.read_csv(
        ORDERS_FILE,
        usecols=[
            "order_id",
            "user_id",
            "order_number",
            "eval_set"
        ]
    )

    return orders


def process_purchase_history(chunk_size=100_000):
    """
    Process the large order_products__prior.csv file
    in chunks so we don't load the entire file into RAM.
    """

    orders = load_orders()
    products = load_product_catalog()

    output_file = OUTPUT_DIR / "purchase_history.csv"

    if output_file.exists():
        output_file.unlink()

    first_chunk = True
    total_rows = 0

    for chunk in pd.read_csv(
        ORDER_PRODUCTS_FILE,
        chunksize=chunk_size
    ):

        merged = chunk.merge(
            orders,
            on="order_id",
            how="left"
        )

        merged = merged.merge(
            products,
            on="product_id",
            how="left"
        )

        selected_columns = [
            "user_id",
            "order_id",
            "order_number",
            "product_id",
            "product_name",
            "aisle_name",
            "department_name",
            "add_to_cart_order",
            "reordered"
        ]

        merged = merged[selected_columns]

        merged.to_csv(
            output_file,
            mode="w" if first_chunk else "a",
            header=first_chunk,
            index=False
        )

        first_chunk = False
        total_rows += len(merged)

        print(
            f"Processed {total_rows:,} purchase records..."
        )

    print("\nPreprocessing completed.")
    print(f"Output file: {output_file}")
    print(f"Total purchase records: {total_rows:,}")


if __name__ == "__main__":
    process_purchase_history()