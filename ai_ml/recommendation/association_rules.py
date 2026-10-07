from pathlib import Path
from collections import Counter, defaultdict

import pandas as pd


# ============================================================
# SmartKart AI - Targeted Association Rule Mining
# ============================================================
#
# Purpose:
#   Find real Instacart products that are purchased together
#   with SmartKart products.
#
# SmartKart mapped Instacart products:
#
#   Milk        -> 16611
#   Bread       -> 20479
#   Cheese      -> 1246
#   Corn Flakes -> 46541
#   Apple       -> 48227
#
# Output:
#   datasets/processed/association_rules.csv
#
# ============================================================


# ============================================================
# Project Paths
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[2]

DATASET_DIR = (
    PROJECT_ROOT
    / "datasets"
    / "instacart"
    / "raw"
)

PROCESSED_DIR = (
    PROJECT_ROOT
    / "datasets"
    / "processed"
)

ORDERS_FILE = (
    DATASET_DIR
    / "orders.csv"
)

ORDER_PRODUCTS_FILE = (
    DATASET_DIR
    / "order_products__prior.csv"
)

PRODUCTS_FILE = (
    DATASET_DIR
    / "products.csv"
)

OUTPUT_FILE = (
    PROCESSED_DIR
    / "association_rules.csv"
)


# ============================================================
# SmartKart Target Products
# ============================================================

SMARTKART_TARGET_IDS = {
    16611,   # Milk
    20479,   # Bread
    1246,    # Cheese
    46541,   # Corn Flakes
    48227,   # Apple
}


# ============================================================
# Configuration
# ============================================================

CHUNK_SIZE = 100_000

# Minimum number of orders in which a pair must appear.
MIN_PAIR_COUNT = 5

# Minimum confidence.
MIN_CONFIDENCE = 0.01

# Minimum lift.
MIN_LIFT = 1.0

# Maximum rules generated per target product.
MAX_RULES_PER_TARGET = 100


# ============================================================
# Utility
# ============================================================

def normalize_id(value):
    """Safely convert an ID to integer."""

    try:
        return int(value)
    except (ValueError, TypeError):
        return None


# ============================================================
# Load Product Names
# ============================================================

def load_product_names():
    """
    Load Instacart product names.
    """

    print("=" * 70)
    print("LOADING PRODUCT NAMES")
    print("=" * 70)

    products = pd.read_csv(
        PRODUCTS_FILE,
        usecols=[
            "product_id",
            "product_name",
        ],
    )

    products["product_id"] = (
        products["product_id"]
        .astype(int)
    )

    product_names = dict(
        zip(
            products["product_id"],
            products["product_name"],
        )
    )

    print(
        f"Products loaded: {len(product_names):,}"
    )

    return product_names


# ============================================================
# Find Target Orders
# ============================================================

def find_target_orders():
    """
    First pass through order_products__prior.csv.

    Finds:
        target product -> set of order IDs

    This tells us which orders contain our SmartKart
    products.
    """

    print()
    print("=" * 70)
    print("PASS 1 - FINDING TARGET PRODUCT ORDERS")
    print("=" * 70)

    target_orders = defaultdict(set)

    total_rows = 0

    for chunk in pd.read_csv(
        ORDER_PRODUCTS_FILE,
        usecols=[
            "order_id",
            "product_id",
        ],
        chunksize=CHUNK_SIZE,
    ):

        total_rows += len(chunk)

        chunk["product_id"] = pd.to_numeric(
            chunk["product_id"],
            errors="coerce",
        )

        chunk = chunk.dropna(
            subset=["product_id"]
        )

        chunk["product_id"] = (
            chunk["product_id"]
            .astype(int)
        )

        matched = chunk[
            chunk["product_id"].isin(
                SMARTKART_TARGET_IDS
            )
        ]

        for product_id, group in matched.groupby(
            "product_id"
        ):

            target_orders[
                int(product_id)
            ].update(
                group["order_id"]
                .astype(int)
                .tolist()
            )

        if total_rows % 1_000_000 < CHUNK_SIZE:
            print(
                f"Processed rows: {total_rows:,}"
            )

    print()
    print(
        f"Total rows scanned: {total_rows:,}"
    )

    for product_id in sorted(
        SMARTKART_TARGET_IDS
    ):
        print(
            f"Target {product_id}: "
            f"{len(target_orders[product_id]):,} orders"
        )

    return target_orders


# ============================================================
# Build Target Order Set
# ============================================================

def build_target_order_lookup(
    target_orders
):
    """
    Create:

        order_id -> set(target product IDs)

    """

    order_to_targets = defaultdict(set)

    for product_id, order_ids in target_orders.items():

        for order_id in order_ids:

            order_to_targets[
                order_id
            ].add(product_id)

    return order_to_targets


# ============================================================
# Mine Co-occurrences
# ============================================================

def mine_cooccurrences(
    target_orders
):
    """
    Second pass through purchase data.

    For every order containing a SmartKart target:

        Target Product
              +
        Other Products
              ↓
        Co-occurrence count

    Also calculates product support counts.
    """

    print()
    print("=" * 70)
    print("PASS 2 - MINING PRODUCT CO-OCCURRENCES")
    print("=" * 70)

    order_to_targets = (
        build_target_order_lookup(
            target_orders
        )
    )

    # Product -> number of unique prior orders containing product
    product_order_counts = Counter()

    # Target product -> candidate product -> pair order count
    pair_counts = defaultdict(
        Counter
    )

    # Number of unique prior orders
    total_orders = 0

    # We need to process complete orders.
    # The prior file is ordered by order_id.
    current_order_id = None
    current_products = set()

    total_rows = 0

    def process_order(
        order_id,
        product_ids,
    ):
        """
        Process one complete shopping basket.
        """

        nonlocal total_orders

        if order_id is None:
            return

        if not product_ids:
            return

        total_orders += 1

        unique_products = set(
            product_ids
        )

        # Product support
        for product_id in unique_products:

            product_order_counts[
                product_id
            ] += 1

        # Is this order relevant to SmartKart?
        targets = order_to_targets.get(
            int(order_id)
        )

        if not targets:
            return

        # For each SmartKart target,
        # count all products purchased with it.
        for target_id in targets:

            for candidate_id in unique_products:

                if candidate_id == target_id:
                    continue

                pair_counts[
                    target_id
                ][candidate_id] += 1

    # --------------------------------------------------------
    # Read purchase history in chunks
    # --------------------------------------------------------

    for chunk in pd.read_csv(
        ORDER_PRODUCTS_FILE,
        usecols=[
            "order_id",
            "product_id",
        ],
        chunksize=CHUNK_SIZE,
    ):

        total_rows += len(chunk)

        chunk["order_id"] = pd.to_numeric(
            chunk["order_id"],
            errors="coerce",
        )

        chunk["product_id"] = pd.to_numeric(
            chunk["product_id"],
            errors="coerce",
        )

        chunk = chunk.dropna(
            subset=[
                "order_id",
                "product_id",
            ]
        )

        chunk["order_id"] = (
            chunk["order_id"]
            .astype(int)
        )

        chunk["product_id"] = (
            chunk["product_id"]
            .astype(int)
        )

        # ----------------------------------------------------
        # Process rows while preserving orders across chunks
        # ----------------------------------------------------

        for order_id, group in chunk.groupby(
            "order_id",
            sort=False,
        ):

            order_id = int(order_id)

            products_in_group = set(
                group["product_id"]
                .tolist()
            )

            # First order
            if current_order_id is None:

                current_order_id = order_id

                current_products = (
                    products_in_group
                )

                continue

            # Same order continues
            if order_id == current_order_id:

                current_products.update(
                    products_in_group
                )

                continue

            # New order:
            # finish previous order
            process_order(
                current_order_id,
                current_products,
            )

            current_order_id = order_id

            current_products = (
                products_in_group
            )

        if total_rows % 1_000_000 < CHUNK_SIZE:
            print(
                f"Processed rows: {total_rows:,}"
            )

    # Process final order
    process_order(
        current_order_id,
        current_products,
    )

    print()
    print(
        f"Purchase rows processed: "
        f"{total_rows:,}"
    )

    print(
        f"Unique prior orders: "
        f"{total_orders:,}"
    )

    return (
        pair_counts,
        product_order_counts,
        total_orders,
    )


# ============================================================
# Generate Association Rules
# ============================================================

def generate_rules(
    pair_counts,
    product_order_counts,
    total_orders,
    product_names,
):
    """
    Convert co-occurrence counts into:

        support
        confidence
        lift

    """

    print()
    print("=" * 70)
    print("GENERATING ASSOCIATION RULES")
    print("=" * 70)

    rules = []

    for target_id in sorted(
        SMARTKART_TARGET_IDS
    ):

        target_support_count = (
            product_order_counts.get(
                target_id,
                0,
            )
        )

        if target_support_count == 0:
            print(
                f"WARNING: Target {target_id} "
                f"has no purchase records."
            )
            continue

        target_rules = []

        for candidate_id, pair_count in (
            pair_counts[target_id].items()
        ):

            if pair_count < MIN_PAIR_COUNT:
                continue

            candidate_support_count = (
                product_order_counts.get(
                    candidate_id,
                    0,
                )
            )

            if candidate_support_count == 0:
                continue

            # ------------------------------------------------
            # Support
            # ------------------------------------------------

            support = (
                pair_count
                / total_orders
            )

            # ------------------------------------------------
            # Confidence
            #
            # P(B | A)
            # ------------------------------------------------

            confidence = (
                pair_count
                / target_support_count
            )

            # ------------------------------------------------
            # Lift
            #
            # P(B|A) / P(B)
            # ------------------------------------------------

            candidate_probability = (
                candidate_support_count
                / total_orders
            )

            if candidate_probability == 0:
                continue

            lift = (
                confidence
                / candidate_probability
            )

            if confidence < MIN_CONFIDENCE:
                continue

            if lift < MIN_LIFT:
                continue

            target_rules.append(
                {
                    "antecedent_product_id": target_id,
                    "consequent_product_id": candidate_id,
                    "support": support,
                    "confidence": confidence,
                    "lift": lift,
                    "product_name": product_names.get(
                        target_id,
                        "Unknown",
                    ),
                    "recommended_product_name": product_names.get(
                        candidate_id,
                        "Unknown",
                    ),
                }
            )

        # ----------------------------------------------------
        # Keep strongest rules
        # ----------------------------------------------------

        target_rules.sort(
            key=lambda rule: (
                rule["lift"],
                rule["confidence"],
                rule["support"],
            ),
            reverse=True,
        )

        target_rules = target_rules[
            :MAX_RULES_PER_TARGET
        ]

        rules.extend(
            target_rules
        )

        print(
            f"Target {target_id} "
            f"({product_names.get(target_id, 'Unknown')}): "
            f"{len(target_rules)} rules"
        )

    return pd.DataFrame(
        rules,
        columns=[
            "antecedent_product_id",
            "consequent_product_id",
            "product_name",
            "recommended_product_name",
            "support",
            "confidence",
            "lift",
        ],
    )


# ============================================================
# Save Rules
# ============================================================

def save_rules(rules_df):
    """
    Save association rules to CSV.
    """

    PROCESSED_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    rules_df.to_csv(
        OUTPUT_FILE,
        index=False,
    )

    print()
    print("=" * 70)
    print("RULES SAVED")
    print("=" * 70)

    print(
        f"Output file:\n{OUTPUT_FILE}"
    )

    print(
        f"Total rules: {len(rules_df):,}"
    )


# ============================================================
# Display Sample Rules
# ============================================================

def display_sample_rules(
    rules_df,
    product_names,
):
    """
    Display strongest rules for each SmartKart target.
    """

    print()
    print("=" * 70)
    print("SAMPLE SMARTKART ASSOCIATION RULES")
    print("=" * 70)

    if rules_df.empty:

        print(
            "No association rules were generated."
        )

        return

    for target_id in sorted(
        SMARTKART_TARGET_IDS
    ):

        target_rules = rules_df[
            rules_df[
                "antecedent_product_id"
            ]
            == target_id
        ].head(5)

        print()

        print(
            f"### {target_id} - "
            f"{product_names.get(target_id, 'Unknown')} ###"
        )

        if target_rules.empty:

            print(
                "No rules found."
            )

            continue

        print(
            target_rules[
                [
                    "product_name",
                    "recommended_product_name",
                    "support",
                    "confidence",
                    "lift",
                ]
            ].to_string(
                index=False
            )
        )


# ============================================================
# Main
# ============================================================

def main():

    print()
    print("=" * 70)
    print("SMARTKART AI - TARGETED ASSOCIATION RULE MINING")
    print("=" * 70)

    print()
    print(
        "Target products:"
    )

    for product_id in sorted(
        SMARTKART_TARGET_IDS
    ):
        print(
            f"  {product_id}"
        )

    # --------------------------------------------------------
    # Check files
    # --------------------------------------------------------

    if not ORDER_PRODUCTS_FILE.exists():

        raise FileNotFoundError(
            f"Missing file: "
            f"{ORDER_PRODUCTS_FILE}"
        )

    if not PRODUCTS_FILE.exists():

        raise FileNotFoundError(
            f"Missing file: "
            f"{PRODUCTS_FILE}"
        )

    # --------------------------------------------------------
    # Load product names
    # --------------------------------------------------------

    product_names = (
        load_product_names()
    )

    # --------------------------------------------------------
    # Pass 1
    # --------------------------------------------------------

    target_orders = (
        find_target_orders()
    )

    # --------------------------------------------------------
    # Pass 2
    # --------------------------------------------------------

    (
        pair_counts,
        product_order_counts,
        total_orders,
    ) = mine_cooccurrences(
        target_orders
    )

    # --------------------------------------------------------
    # Generate rules
    # --------------------------------------------------------

    rules_df = generate_rules(
        pair_counts,
        product_order_counts,
        total_orders,
        product_names,
    )

    # --------------------------------------------------------
    # Save
    # --------------------------------------------------------

    save_rules(
        rules_df
    )

    # --------------------------------------------------------
    # Display samples
    # --------------------------------------------------------

    display_sample_rules(
        rules_df,
        product_names,
    )

    # --------------------------------------------------------
    # Complete
    # --------------------------------------------------------

    print()
    print("=" * 70)
    print("ASSOCIATION RULE MINING COMPLETE")
    print("=" * 70)


# ============================================================
# Run
# ============================================================

if __name__ == "__main__":
    main()