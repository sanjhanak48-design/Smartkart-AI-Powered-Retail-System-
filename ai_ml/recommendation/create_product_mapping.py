from pathlib import Path
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[2]

INSTACART_PRODUCTS_FILE = (
    PROJECT_ROOT
    / "datasets"
    / "instacart"
    / "raw"
    / "products.csv"
)

OUTPUT_FILE = (
    PROJECT_ROOT
    / "datasets"
    / "processed"
    / "product_mapping.csv"
)


SMARTKART_PRODUCTS = [
    (1, "Milk", 16611),
    (2, "Bread", 20479),
    (3, "Cheese", 1246),
    (4, "Corn Flakes", 46541),
    (5, "Apple", 48227),
    (6, "Banana", 24852),
    (7, "Yogurt", 35073),
    (8, "Butter", 5460),
    (9, "Eggs", 5038),
    (10, "Chicken", 43063),
    (11, "Tomato", 25162),
    (12, "Onion", 47016),
    (13, "Orange", 23540),
    (14, "Strawberries", 16797),
    (15, "Cereal", 20955),
    (16, "Peanut Butter", 7761),
    (17, "Cookies", 25114),
]


def main():

    print("=" * 60)
    print("SMARTKART PRODUCT MAPPING")
    print("=" * 60)

    if not INSTACART_PRODUCTS_FILE.exists():
        raise FileNotFoundError(
            f"File not found: {INSTACART_PRODUCTS_FILE}"
        )

    df = pd.read_csv(INSTACART_PRODUCTS_FILE)

    print(f"Instacart products loaded: {len(df)}")

    lookup = dict(
        zip(
            df["product_id"],
            df["product_name"]
        )
    )

    mapping = []

    for smartkart_id, smartkart_name, instacart_id in SMARTKART_PRODUCTS:

        instacart_name = lookup.get(instacart_id)

        if instacart_name is None:
            print(
                f"WARNING: Instacart ID {instacart_id} not found"
            )
            continue

        mapping.append(
            {
                "smartkart_product_id": smartkart_id,
                "smartkart_product_name": smartkart_name,
                "instacart_product_id": instacart_id,
                "instacart_product_name": instacart_name,
                "match_method": "exact_name",
                "match_confidence": 1.0,
            }
        )

    mapping_df = pd.DataFrame(mapping)

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    mapping_df.to_csv(
        OUTPUT_FILE,
        index=False
    )

    print()
    print(f"Mapping rows created: {len(mapping_df)}")
    print()
    print(mapping_df.to_string(index=False))

    print()
    print("=" * 60)
    print("PRODUCT MAPPING COMPLETE")
    print("=" * 60)
    print(f"Saved to: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()