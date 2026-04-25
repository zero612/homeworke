# 📊 U.S. Retail Giants Financial Health Analyzer

> A Python-based financial health assessment tool comparing Walmart, Costco, and Kroger using WRDS Compustat data.

[![Python Version]

[![License]

[![WRDS]
## 📌 Project Overview

This project is a **small data product** developed for the ACC102 Mini Assignment (Track 2 – GitHub Data Analysis Project). It provides an automated financial health assessment of three major U.S. retail companies:

| Ticker | Company | Business Model |
|:---|:---|:---|
| **WMT** | Walmart Inc. | General merchandise retailer |
| **COST** | Costco Wholesale Corp. | Membership warehouse club |
| **KR** | Kroger Co. | Supermarket chain |

The tool retrieves **real financial statement data** from the **WRDS Compustat North America** database, calculates **15+ key financial ratios** across four dimensions (profitability, solvency, efficiency, and growth), and generates visual reports to support investment and analytical decision-making.

### 🎯 Target Audience

- **Retail industry investors** comparing potential investment opportunities
- **Financial analysts** conducting peer benchmarking
- **Business students** learning financial statement analysis with real-world data

---

## 🚀 Key Features

| Feature | Description |
|:---|:---|
| 🔗 **WRDS Integration** | Connects directly to WRDS Compustat via Python API to fetch real financial data |
| 📊 **Comprehensive Ratio Calculation** | Computes profitability, solvency, efficiency, and growth metrics automatically |
| 📈 **Multi-dimensional Visualization** | Generates bar charts, radar charts, and trend analysis for intuitive comparison |
| 🏆 **Composite Scoring** | Produces normalized rankings of overall financial health |
| 🔄 **Reproducible Workflow** | Fully modular code that can be rerun with different tickers or year ranges |

---

## 📁 Repository Structure
us-retail-financial-analyzer


├── README.md # Project documentation (this file)

├── requirements.txt # Python dependencies

├── .gitignore # Git ignore rules



├── financial_analysis.ipynb # Main Jupyter Notebook (full analysis)



├── src/ # Modular Python scripts

│ ├── data_loader.py # WRDS data retrieval module

│ ├── ratio_engine.py # Financial ratio calculation engine

│ └── visualizer.py # Visualization module



├── images/ # Output visualizations

│ ├── profitability_comparison.png # Profitability bar chart

│ ├── radar_chart.png # Multi-dimensional radar chart

│ ├── trend_wmt.png # Walmart trend analysis

│ ├── trend_cost.png # Costco trend analysis

│ └── trend_kr.png # Kroger trend analysis



├── data/ # Sample output data

│ └── financial_ratios_2024.csv # Calculated ratios for latest year



└── video/

└── demo_video.mp4 # 1-3 minute demonstration video

---

## 🔧 Installation & Setup

### Prerequisites

- **Python 3.11** or higher
- **WRDS account** with access to **Compustat North America** (Fundamentals Annual)
- Git (for cloning the repository)

### Step 1: Clone the Repository

git clone https://github.com/zero612/homeworke.git

### Step 2: Install Dependencies

requirements.txt contains:

text

wrds>=3.1.0

pandas>=1.3.0

numpy>=1.21.0

matplotlib>=3.4.0

seaborn>=0.11.0

jupyter>=7.4.5

### Step 3: Configure WRDS Connection

The first time you run the code, you will be prompted to enter your WRDS username and password. After successful authentication, you will be asked whether to create a .pgpass file. Type y to save your credentials securely for future use.
Note: Your institution must have an active WRDS subscription with Compustat North America access.
________________________________________
## 📖 Usage
### Quick Start (Jupyter Notebook)
1.	Launch Jupyter Notebook:
bash
jupyter notebook
2.	Open financial_analysis.ipynb
3.	Run all cells sequentially (Cell → Run All)
4.	The notebook will:

  	 o	Connect to WRDS and fetch data for WMT, COST, KR (2020–2024)

  	 o	Calculate all financial ratios

  	 o	Display summary tables

  	 o	Generate and display visualizations
### Customizing the Analysis
To analyze different companies or time periods, modify the parameters in the main execution cell:
```
python
# Change tickers (any valid Compustat ticker)
TICKERS = ['WMT', 'COST', 'KR', 'TGT', 'DG']

# Change year range
START_YEAR = 2018
END_YEAR = 202
```
________________________________________
## 📊 Financial Metrics Calculated
### 1️⃣ Profitability
|Metric|Formula|Interpretation|
|:---|:---|:---|
|Gross Margin|(Revenue - COGS) / Revenue|Pricing power and cost control|
|Net Margin|Net Income / Revenue|Overall profitability|
|ROA|Net Income / Total Assets|Asset utilization efficiency|
|ROE|Net Income / Total Equity|Return to shareholders|

### 2️⃣ Solvency
|Metric|Formula|Warning Threshold|
|:---|:---|:---|
|Current Ratio|	Current Assets / Current Liabilities|	< 1.5|
|Quick Ratio|	(Current Assets - Inventory) / Current Liabilities|	< 1.0|
|Debt-to-Assets|	Total Liabilities / Total Assets|	> 70%|

### 3️⃣ Efficiency
|Metric|Formula|
|:---|:---|
|Inventory Turnover|	COGS / Average Inventory|
|Receivables Turnover	|Revenue / Average Receivables|
|Asset Turnover	|Revenue / Average Total Assets|

### 4️⃣ Growth
|Metric|Formula|
|:---|:---|
|Revenue Growth (YoY)|	(Current Revenue - Prior Revenue) / Prior Revenue|
|Net Income Growth (YoY)|	(Current Net Income - Prior Net Income) / Prior Net Income|
________________________________________
## 📈 Sample Output
### Profitability Comparison (2024)
<img width="4168" height="1192" alt="Image" src="https://github.com/user-attachments/assets/2803efdc-97b9-4007-824c-fcef4a9743da" />

### Multi-dimensional Radar Chart (2024)
<img width="2848" height="2361" alt="Image" src="https://github.com/user-attachments/assets/f09580af-a5cb-4291-9dc3-e7b2d0ccb0c3" />

### Trend Analysis (Walmart)
<img width="4171" height="2957" alt="Image" src="https://github.com/user-attachments/assets/941ec214-fa09-4b76-97ac-da7a69671c42" />
<img width="4171" height="2957" alt="Image" src="https://github.com/user-attachments/assets/f14b9bf8-55ea-4ba5-b7db-ab9c23d881ec" />
<img width="4171" height="2957" alt="Image" src="https://github.com/user-attachments/assets/54ce182d-813e-47a2-8a37-4252c7cc2975" />

### Summary Table (2024)
|Company|	Gross Margin|	Net Margin|	ROE	|Current Ratio|	Debt-to-Assets|	Inventory Turnover|
|:---|:---|:---|:---|:---|:---|:---|
|Walmart|	25.93%|	2.4%|	18.5%|	0.83|	64.12%	|8.71x|
|Costco|	13.49%|	2.9%|	31.19%| 0.97|	66.17%|	11.8x|
|Kroger|	22.24%|	1.44%|	18.63%|	0.81|	77.03%|	16.42x|
________________________________________
## 🔍 Key Insights
Based on the 2020–2024 analysis:
### 1.	Costco demonstrates the strongest overall financial health:
-	Highest ROE (≈25.93%) driven by efficient asset utilization
-	Most conservative capital structure (lowest debt-to-assets)
-	Superior inventory turnover (≈16.42x) reflecting membership model efficiency
### 2.	Walmart shows stable and consistent performance:
-	Solid gross margins (≈24-25%)
-	Steady revenue growth (≈3-5% annually)
-	Moderate leverage with improving trends
### 3.	Kroger exhibits higher financial risk:
-	Highest debt-to-assets ratio (≈77%), exceeding industry norms
-	Lower current ratio indicating potential liquidity pressure
-	Thinner net margins compared to peers
________________________________________
## 🛠️ Technical Implementation
### Data Source
-	WRDS Compustat North America – Fundamentals Annual (funda table)
-	Data accessed on: 4.25
### Key Compustat Fields Used
|Field|	Description|
|:---|:---|
|tic|	Ticker symbol|
|fyear|	Fiscal year|
|at|	Assets – Total|
|lt|	Liabilities – Total|
|ceq|	Common Equity – Total|
|sale|	Sales/Turnover (Revenue)|
|ni|	Net Income|
### Code Architecture
•	**Modular Design**: Separated into data loading, calculation, and visualization modules

•	**Error Handling**: Graceful fallback for missing data fields

•	**Reproducibility**: Fixed random seed for consistent outputs where applicable
________________________________________
## 📝 Reflection (Summary)
### This project demonstrates the integration of Python programming with accounting domain knowledge to create a practical financial analysis tool. Key learning outcomes include:
-	Connecting to professional financial databases (WRDS) via API
-	Implementing financial ratio calculations programmatically
-	Designing user-friendly visualizations for comparative analysis
-	Structuring code as a reusable data product
### Limitations acknowledged:
-	Analysis limited to three companies; industry-wide comparison would require broader sampling
-	Does not account for macroeconomic factors or industry cycles
-	Ratio weights in composite scoring are subjective
### Future improvements:
-	Expand to full retail sector using SIC/NAICS codes
-	Incorporate Altman Z-score for bankruptcy risk assessment
-	Develop Streamlit web interface for interactive exploration
________________________________________
## 📹 Demo Video
A 1–3 minute demonstration video is available in the video/ folder
**🔗 Watch Demo Video**
**The video covers**:
-	Overview of the GitHub repository structure
-	Running the Jupyter Notebook
-	Key visualizations and insights
________________________________________
## 📄 AI Use Disclosure

In accordance with the ACC102 assignment requirements, the following AI tools were used in the development of this project:

| Tool | Version | Access Date | Purpose |
|:---|:---|:---|:---|
| DeepSeek | Web | 2026-04-18 | Assisted with WRDS SQL query syntax, Compustat field mapping, and overall code structure planning |
| DeepSeek | Web | 2026-04-19 | Helped debug Jupyter Notebook display issues and image saving configuration |
| DeepSeek | Web | 2026-04-22 | Provided guidance on financial ratio calculation logic and data visualization design |
| DeepSeek | Web | 2026-04-23 | Assisted with troubleshooting Costco data retrieval issues (datafmt filtering and deduplication logic) |
| DeepSeek | Web | 2026-04-25 | Helped refine README documentation structure, Markdown formatting |

All AI-generated suggestions were reviewed, tested, and modified by the author. The final code, analysis, interpretations, and documentation represent my own intellectual contribution and understanding. Specific modifications made to AI suggestions include:

- Adjusting SQL query conditions to ensure all three companies' data were correctly retrieved
- Modifying data deduplication logic to handle multiple data formats (STD vs SUMM_STD)
- Customizing visualization parameters for clarity and professional presentation
- Adapting reflection content to reflect personal learning experiences
________________________________________
## 👤 Author
-	Name: Jiayi Chen
-	Student ID: 2468729
-	Program: BA Accounting – Year 2
-	Course: ACC102
-	Institution: Xi'an Jiaotong-Liverpool University
-	Submission Date: 4.26
________________________________________
## 📜 License
This project is submitted as part of an academic assignment and is licensed under the MIT License. See the LICENSE file for details.
________________________________________
## 🙏 Acknowledgments
-	WRDS (Wharton Research Data Services) for providing access to Compustat data
-	Course instructors for guidance on Python and financial analysis methodologies
-	Compustat data sourced from S&P Global Market Intelligence


