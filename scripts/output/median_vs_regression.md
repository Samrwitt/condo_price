# Median vs regression (USD / m²)

For each capital with at least **500** city-filtered apartment listings, we train Ridge regression to predict `log(USD/m²)` from condo features (area, rooms, bedrooms, bathrooms, construction year, building floors, apartment floor, plus missingness flags). Training minimizes **MSE** on log price density plus an L2 penalty on weights. The baseline predicts the **train median** USD/m² for every listing.

Held-out **MAE** on USD/m² is the main comparison. We also report an **80 m²** city-level estimate from both methods.

| City | n | Median MAE $/m² | Model MAE $/m² | Δ MAE | Better | Median 80 m² | Model 80 m² |
| --- | ---: | ---: | ---: | ---: | --- | ---: | ---: |
| Athens | 816 | 1,639 | 1,424 | +214 (+13.1%) | model | $267,149 | $221,453 |
| Budapest | 3385 | 929 | 907 | +21 (+2.3%) | model | $221,893 | $187,825 |
| Minsk | 4104 | 320 | 283 | +37 (+11.5%) | model | $105,781 | $119,937 |
| Moscow | 1451 | 1,266 | 706 | +560 (+44.2%) | model | $256,764 | $463,334 |
| Prague | 718 | 1,133 | 1,128 | +5 (+0.4%) | tie | $464,911 | $440,554 |
| Riga | 909 | 1,226 | 1,061 | +164 (+13.4%) | model | $242,581 | $219,397 |
| Tashkent | 1464 | 390 | 334 | +56 (+14.5%) | model | $99,264 | $127,679 |
| Warsaw | 934 | 1,087 | 1,057 | +30 (+2.7%) | model | $299,448 | $295,605 |

## Takeaway

- Cities modeled: **8** (need ≥ 500 listings).
- Model lower held-out MAE: **7**; median lower: **0**; roughly tied (<1%): **1**.
- When features are informative (rooms, year, floors), regression can beat a flat median on listing-level error. The city headline for an 80 m² condo can still stay close to the median, because that is already a strong pooled estimate.
- Thin cities stay on the median method; a model there would overfit.
