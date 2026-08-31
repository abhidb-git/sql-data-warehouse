# 🏛️ Data Warehouse and Analytics Project (MySQL)

Welcome to the **Data Warehouse and Analytics Project**! 🚀

This repository demonstrates how to build a complete data warehousing and analytics solution using **MySQL**. Built using the **Medallion Architecture (Bronze, Silver, and Gold layers)**, this project combines sales data from two different source systems (ERP and CRM), cleans up raw data, builds a Star Schema data model, and runs SQL queries to generate business insights.

---

## 🏗️ Data Architecture

The data architecture follows the **Bronze**, **Silver**, and **Gold** layer flow:

* **CRM & ERP Source Data (CSV Files)**
  * ↓
* **Bronze Database (Raw Data):** Stores raw data as-is from source files
  * ↓
* **Silver Database (Cleaned Data):** Data cleansing, standardization & mapping
  * ↓
* **Gold Database (Star Schema):** Business-ready Fact & Dimension tables

### Layer Breakdown:
1. **Bronze Layer (`bronze` DB):** Stores raw data exactly as it comes from the CRM and ERP source systems without changing any structures.
2. **Silver Layer (`silver` DB):** Cleans and transforms the data—handling missing values, fixing date formats, standardizing categories, and mapping customer keys.
3. **Gold Layer (`gold` DB):** Builds a Star Schema with Fact (`fact_sales`) and Dimension (`dim_customers`, `dim_products`) tables optimized for analytical reporting.

---

## 📁 Repository Directory Structure

```text

├── code_explanation/
│   ├── bronze_dataLoad_code_explanation.sql
│   ├── silver_dataLoad_code_explanation.sql
│   └── dwh_gold_quality_check.sql
├── datasets/
│   ├── source_crm/               # Raw CRM CSV files
│   └── source_erp/               # Raw ERP CSV files
├── docs/
│   ├── Data_architecture.png     # Data architecture diagram
│   ├── data_flow.drawio          # Data flow diagram
│   └── data_integration.drawio   # Data model diagram
├── EDA/
│   ├── EDA.sql                   # Initial exploratory data analysis
│   └── advanced_data_analytics.sql # Customer behavior & business reports
├── scripts/
│   ├── bronze_layer/             # SQL scripts for loading raw data
│   ├── silver_layer/             # SQL scripts for data cleaning & transformation
│   └── gold_layer/               # SQL scripts for Star Schema data modeling
├── .gitignore
├── LICENSE
└── README.md
```
---

## 🛠️ Project Phases & Steps

### 1. Data Ingestion (`scripts/bronze_layer/`)
* Created staging tables to match raw CSV structures.
* Wrote SQL scripts to bulk load CRM and ERP datasets into MySQL.
* Scripts explanations are documented in `code_explanation/bronze_dataLoad_code_explanation.sql`.

### 2. Data Cleaning & Transformation (`scripts/silver_layer/`)
* Cleaned messy data and fixed quality issues:
  * Handled `NULL` and missing values with fallback logic.
  * Standardized gender, marital status, and category text values across systems.
  * Formatted date columns for consistent reporting.
* Ran data quality checks using `code_explanation/dwh_gold_quality_check.sql`.

### 3. Data Modeling (`scripts/gold_layer/`)
* Built a user-friendly Star Schema model for analytical queries:
  * **Fact Table:** `fact_sales` (contains sales metrics, quantities, prices, and links).
  * **Dimension Tables:** `dim_customers`, `dim_products` (contains customer and product details).

---

## 📊 Analytics & Reporting (`EDA/`)

After loading the Gold layer, analytical SQL queries were written in `advanced_data_analytics.sql` to answer core business questions across:

* **Customer Behavior:** Analyzing customer groups, purchase frequency, and lifetime spent.
* **Product Performance:** Identifying top-selling products, key revenue drivers, and underperforming items.
* **Sales Trends:** Tracking monthly revenue trends and overall sales growth.

---

## 🛠️ Tools & Environment

* **Database:** MySQL
* **SQL Client:** DBeaver / MySQL Workbench
* **Diagram Tools:** Draw.io

---

## 📜 License

This project is licensed under the **MIT License**.
