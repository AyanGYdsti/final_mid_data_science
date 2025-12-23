# 📊 Analisis Clustering Kemiskinan Provinsi di Indonesia

## 🔍 Deskripsi Proyek

Proyek ini bertujuan untuk **mengelompokkan provinsi di Indonesia berdasarkan karakteristik kemiskinan** menggunakan metode *unsupervised learning*. Analisis dilakukan dengan mengombinasikan:

* **UMAP (Uniform Manifold Approximation and Projection)** untuk reduksi dimensi
* **K-Means** dengan *Auto Elbow Detection*
* **DBSCAN** dengan *Auto Epsilon (Knee Detection)*

Pendekatan ini memungkinkan identifikasi **pola kemiskinan nasional** sekaligus **provinsi dengan karakteristik ekstrem (outlier)** yang memerlukan perhatian kebijakan khusus.

---

## 🗂️ Struktur Folder

```
project/
│── data_kemiskinan.xlsx
│── clustering_kemiskinan.R
│── README.md
```

---

## 📦 Library yang Digunakan

Script akan otomatis menginstal library jika belum tersedia:

* tidyverse
* factoextra
* umap
* dbscan
* pheatmap
* cluster
* clusterSim
* readxl
* ggplot2

---

## ▶️ Cara Menjalankan Program

### 1️⃣ Persiapan Data

Pastikan file **`data_kemiskinan.xlsx`** tersedia dengan kolom indikator berikut:

* persentase_miskin
* jumlah_miskin
* pdrb_perkapita
* rata2_lama_sekolah
* tingkat_pengangguran
* gini_ratio
* indeks_pembangunan_manusia
* kepadatan_penduduk_per_km_persegi
* rata_rata_pengeluaran_per_kapita

### 2️⃣ Jalankan Script

Buka R / RStudio lalu jalankan:

```r
source("clustering_kemiskinan.R")
```

Seluruh proses akan berjalan otomatis dari awal hingga akhir.

---

## 🔄 Alur Analisis

### 1. Preprocessing Data

* Pembersihan missing value
* Konversi format numerik
* **Robust Scaling** untuk mengurangi pengaruh outlier

### 2. Reduksi Dimensi (UMAP)

UMAP digunakan untuk memproyeksikan indikator kemiskinan multidimensi ke dalam ruang 2D agar mudah divisualisasikan dan dikelompokkan.

Output:

* Visualisasi UMAP (UMAP1 vs UMAP2)
* Setiap titik merepresentasikan satu provinsi

---

## 🤖 Proses Clustering

### 🔹 K-Means (Auto Elbow)

* Jumlah cluster diuji dari k = 1 hingga 10
* Titik siku (elbow) ditentukan otomatis secara geometris
* Menghasilkan:

  * Nilai K optimal
  * Elbow Plot
  * Visualisasi cluster K-Means

**Catatan:** K-Means memaksa seluruh data masuk ke cluster, termasuk data ekstrem.

---

### 🔹 DBSCAN (Auto Epsilon)

* Parameter `minPts = 3`
* Nilai epsilon ditentukan otomatis dari *k-NN distance plot*
* Mampu mendeteksi **noise/outlier (Cluster 0)**

**Keunggulan DBSCAN:**

* Tidak memaksakan struktur cluster
* Mengidentifikasi provinsi dengan karakteristik kemiskinan sangat unik

---

## 📈 Evaluasi Model

### 1️⃣ Silhouette Score

* Nilai mendekati **1** menunjukkan kualitas cluster yang baik
* DBSCAN menunjukkan pemisahan cluster yang lebih alami

### 2️⃣ Davies–Bouldin Index (DBI)

* Nilai mendekati **0** lebih baik
* DBI DBSCAN dihitung tanpa noise agar hasil adil

### 3️⃣ Analisis Noise

* Provinsi dalam **Cluster 0 (Noise)** memiliki karakteristik kemiskinan ekstrem
* Provinsi ini direkomendasikan sebagai **prioritas kebijakan khusus**

---

## 🔥 Profiling Cluster (DBSCAN)

### Heatmap Karakteristik

* Rata-rata indikator kemiskinan per cluster
* Skala per kolom untuk memudahkan perbandingan

**Interpretasi Warna:**

* 🔵 Biru: nilai rendah
* ⚪ Putih: nilai rata-rata
* 🔴 Merah: nilai tinggi

Heatmap ini membantu memahami perbedaan karakteristik kemiskinan antar cluster.

---

## 📋 Daftar Provinsi per Cluster

Script secara otomatis menampilkan:

* ID cluster
* Jumlah provinsi per cluster
* Nama provinsi dalam setiap cluster

Output ini siap digunakan untuk **tabel jurnal atau laporan penelitian**.

---

## ✅ Kesimpulan

1. **DBSCAN lebih unggul** untuk analisis kemiskinan karena mampu menangani outlier
2. **UMAP efektif** untuk visualisasi dan peningkatan kualitas clustering
3. Provinsi outlier membutuhkan pendekatan kebijakan yang lebih spesifik

---

## 🚀 Pengembangan Lanjutan

* Integrasi data spasial (GIS)
* Analisis time-series kemiskinan
* Perbandingan dengan metode HDBSCAN

---

📌 *README ini disusun sebagai dokumentasi teknis dan ilmiah untuk analisis clustering indikator kemiskinan provinsi di Indonesia.*
