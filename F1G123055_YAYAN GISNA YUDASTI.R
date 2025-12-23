# jurnal hasil data science https://docs.google.com/document/d/14mA44bm0Gh6kQ_2k0WrfppakwmDzhRRd/edit?usp=sharing&ouid=104243006301926771570&rtpof=true&sd=true
# ============================================================
# 1. SETUP LIBRARY & DATA
# ============================================================
# Install paket jika belum ada
if(!require(factoextra)) install.packages("factoextra")
if(!require(dbscan)) install.packages("dbscan")
if(!require(umap)) install.packages("umap")
if(!require(pheatmap)) install.packages("pheatmap")
if(!require(readxl)) install.packages("readxl")
if(!require(dplyr)) install.packages("dplyr")
if(!require(ggplot2)) install.packages("ggplot2")

library(tidyverse)            
library(factoextra)
library(umap)
library(readxl)
library(dplyr)
library(ggplot2)
library(pheatmap)
library(dbscan)

# --- FUNGSI BANTUAN: MENCARI TITIK SIKU (ELBOW/KNEE) SECARA OTOMATIS ---
# Fungsi ini menggunakan prinsip geometri untuk mencari titik terjauh 
# dari garis diagonal (titik pembelokan paling tajam).
get_knee_point <- function(x, y) {
  # Normalisasi data ke skala 0-1 agar perhitungan jarak adil
  x_norm <- (x - min(x)) / (max(x) - min(x))
  y_norm <- (y - min(y)) / (max(y) - min(y))
  
  # Buat persamaan garis lurus dari titik pertama ke terakhir
  # Ax + By + C = 0
  x1 <- x_norm[1]; y1 <- y_norm[1]
  x2 <- x_norm[length(x)]; y2 <- y_norm[length(y)]
  
  # Hitung jarak setiap titik kurva ke garis lurus tersebut
  # Rumus jarak titik ke garis
  distances <- abs((y2-y1)*x_norm - (x2-x1)*y_norm + x2*y1 - y2*x1) / 
    sqrt((y2-y1)^2 + (x2-x1)^2)
  
  # Ambil indeks dengan jarak terbesar (itulah sikunya)
  knee_index <- which.max(distances)
  return(knee_index)
}

# --- LOAD DATA ---
# Ganti path sesuai file Anda
data <- read_excel("D:/Sem 5/Data Science/dataset_fix/data_kemiskinan.xlsx")
data <- na.omit(data)

clean_num <- function(x){
  x <- gsub(" ", "", x)
  x <- gsub(",", ".", x)
  return(as.numeric(x))
}

cols_to_clean <- c(
  "persentase_miskin",
  "jumlah_miskin",
  "pdrb_perkapita",
  "rata2_lama_sekolah",
  "tingkat_pengangguran",
  "gini_ratio",
  "indeks_pembangunan_manusia",
  "kepadatan_penduduk_per_km_persegi",
  "rata_rata_pengeluaran_per_kapita"
)

data[, cols_to_clean] <- lapply(data[, cols_to_clean], clean_num)
print(colSums(is.na(data)))
data <- data %>% drop_na()

# Siapkan data numeric
data_num <- data
data_num$provinsi <- NULL
data_num <- as.data.frame(lapply(data_num, as.numeric))

# Robust Scaling
robust_scale <- function(x) (x - median(x)) / mad(x)
data_scaled <- as.data.frame(lapply(data_num, robust_scale))

# ============================================================
# 2. PROSES UMAP (REDUKSI DIMENSI)
# ============================================================
print(">>> Memulai Proses UMAP...")
set.seed(123)

umap_config <- umap.defaults
umap_config$n_neighbors <- 15
umap_config$min_dist <- 0.1
umap_config$metric <- "euclidean"

umap_result <- umap(data_scaled, config = umap_config)

# DataFrame hasil UMAP
umap_df <- as.data.frame(umap_result$layout)
colnames(umap_df) <- c("UMAP1", "UMAP2")
umap_df$provinsi <- data$provinsi

# Visualisasi UMAP Dasar
p_umap <- ggplot(umap_df, aes(x = UMAP1, y = UMAP2, label = provinsi)) +
  geom_point(color = "#2c3e50", size = 3, alpha = 0.8) +
  geom_text(vjust = -0.8, size = 2.5, check_overlap = FALSE) +
  labs(title = "Proyeksi UMAP Indikator Kemiskinan 2024", 
       subtitle = "Base layer untuk clustering") +
  theme_minimal()
print(p_umap)

# ============================================================
# 3. K-MEANS: AUTO-ELBOW SELECTION
# ============================================================
print(">>> Memulai K-Means dengan Auto-Elbow...")
set.seed(123)

# 1. Hitung WSS (Within Sum of Square) untuk k=1 sampai 10
k_range <- 1:10
wss_values <- sapply(k_range, function(k) {
  kmeans(umap_df[,1:2], centers = k, nstart = 25)$tot.withinss
})

# 2. Cari Titik Siku (Elbow) Otomatis
optimal_k_idx <- get_knee_point(k_range, wss_values)
k_optimal <- k_range[optimal_k_idx]

print(paste("Nilai K Optimal (Auto-Elbow):", k_optimal))

# 3. Jalankan K-Means Final
kmeans_model <- kmeans(umap_df[,1:2], centers = k_optimal, nstart = 25)
umap_df$cluster_kmeans <- as.factor(kmeans_model$cluster)

# 4. Visualisasi Elbow
elbow_df <- data.frame(k = k_range, wss = wss_values)
p_elbow <- ggplot(elbow_df, aes(x = k, y = wss)) +
  geom_line(color = "steelblue", size = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = k_optimal, color = "red", linetype = "dashed") +
  annotate("text", x = k_optimal, y = max(wss_values), 
           label = paste("Siku di k =", k_optimal), vjust = 1, color = "red") +
  labs(title = "Metode Elbow Otomatis", y = "Total WSS") +
  scale_x_continuous(breaks = k_range) +
  theme_minimal()

# 5. Visualisasi Hasil Cluster K-Means
p_kmeans <- ggplot(umap_df, aes(x = UMAP1, y = UMAP2, color = cluster_kmeans, label = provinsi)) +
  geom_point(size = 4, alpha = 0.8) +
  geom_text(vjust = -0.8, size = 3, show.legend = FALSE) +
  scale_color_brewer(palette = "Set1") +
  labs(title = paste("K-Means Clustering (k =", k_optimal, ")"),
       subtitle = "Clustering pada hasil reduksi UMAP") +
  theme_minimal() + theme(legend.position = "bottom")

print(p_elbow)
print(p_kmeans)

# ============================================================
# 4. DBSCAN: AUTO-EPSILON SELECTION
# ============================================================
print(">>> Memulai DBSCAN dengan Auto-Epsilon...")

# 1. Hitung Jarak k-NN (k-Nearest Neighbors)
k_minpts <- 3 # Minimal points (biasanya dim + 1)
knn_dist <- dbscan::kNN(umap_df[,1:2], k = k_minpts)
distances <- sort(knn_dist$dist)

# 2. Cari Titik Siku (Knee) Otomatis untuk Epsilon
# Kita pakai fungsi get_knee_point yang sama
# Sumbu X adalah indeks (1 sampai n), Sumbu Y adalah jarak
idx_knee <- get_knee_point(1:length(distances), distances)
eps_optimal <- distances[idx_knee]

print(paste("Nilai Epsilon Optimal (Auto-Knee):", round(eps_optimal, 4)))

# 3. Jalankan DBSCAN Final
dbscan_res <- dbscan(umap_df[,1:2], eps = eps_optimal, minPts = k_minpts)
umap_df$cluster_dbscan <- as.factor(dbscan_res$cluster)

# 4. Visualisasi k-NN Plot
knn_df <- data.frame(index = 1:length(distances), distance = distances)
p_knn <- ggplot(knn_df, aes(x = index, y = distance)) +
  geom_line(color = "steelblue", size = 1) +
  geom_hline(yintercept = eps_optimal, color = "red", linetype = "dashed") +
  annotate("text", x = length(distances)/4, y = eps_optimal, 
           label = paste("Auto Eps:", round(eps_optimal, 3)), vjust = -1, color = "red") +
  labs(title = "k-NN Distance Plot (Auto-Epsilon)", 
       subtitle = "Titik siku dideteksi secara geometris") +
  theme_minimal()

# 5. Visualisasi Hasil Cluster DBSCAN
p_dbscan <- ggplot(umap_df, aes(x = UMAP1, y = UMAP2, color = cluster_dbscan, label = provinsi)) +
  geom_point(aes(shape = (cluster_dbscan == "0")), size = 4, alpha = 0.8) + # Beda bentuk utk noise
  geom_text(vjust = -0.8, size = 3, show.legend = FALSE) +
  scale_color_manual(values = c("0" = "grey70", # Noise
                                "1"="#E41A1C", "2"="#377EB8", "3"="#4DAF4A", "4"="#984EA3", "5"="#FF7F00")) +
  labs(title = paste("DBSCAN Clustering (Eps =", round(eps_optimal, 3), ")"),
       subtitle = "Cluster 0 (Abu-abu) adalah Noise/Outlier",
       color = "Cluster") +
  guides(shape = "none") + # Sembunyikan legend shape
  theme_minimal() + theme(legend.position = "bottom")

print(p_knn)
print(p_dbscan)


# ============================================================
# 5. EVALUASI & KOMPARASI MODEL (Code Block)
# ============================================================

# Install paket khusus DBI jika belum ada
if(!require(clusterSim)) install.packages("clusterSim")
if(!require(cluster)) install.packages("cluster")
if(!require(factoextra)) install.packages("factoextra")
if(!require(dplyr)) install.packages("dplyr")

library(clusterSim)
library(cluster)
library(factoextra)
library(dplyr)

# Menghitung Distance Matrix dari hasil UMAP
dist_matrix <- dist(umap_df[,1:2])

print(">>> MEMULAI EVALUASI KOMPARATIF...")

# ------------------------------------------------------------
# BAGIAN A: SILHOUETTE SCORE (Mendekati 1 = Bagus)
# ------------------------------------------------------------
print("--- 1. Menghitung Silhouette Score ---")

# A1. Silhouette K-Means
sil_kmeans <- silhouette(as.numeric(umap_df$cluster_kmeans), dist_matrix)
avg_sil_kmeans <- summary(sil_kmeans)$avg.width

# A2. Silhouette DBSCAN
# (Perlu penanganan khusus jika ada Noise/Cluster 0)
dbscan_labels <- as.numeric(as.character(umap_df$cluster_dbscan))
sil_dbscan <- silhouette(dbscan_labels, dist_matrix)
avg_sil_dbscan <- summary(sil_dbscan)$avg.width

# Visualisasi Side-by-Side
p1 <- fviz_silhouette(sil_kmeans, print.summary = FALSE) + 
  labs(title = paste("K-Means (Avg:", round(avg_sil_kmeans,3), ")")) + theme_minimal()
p2 <- fviz_silhouette(sil_dbscan, print.summary = FALSE) + 
  labs(title = paste("DBSCAN (Avg:", round(avg_sil_dbscan,3), ")")) + theme_minimal()

# Tampilkan grafik
gridExtra::grid.arrange(p1, p2, ncol = 2)

# ------------------------------------------------------------
# BAGIAN B: DAVIES-BOULDIN INDEX (Mendekati 0 = Bagus)
# ------------------------------------------------------------
print("--- 2. Menghitung Davies-Bouldin Index (DBI) ---")

# B1. DBI K-Means
dbi_kmeans_res <- index.DB(umap_df[,1:2], as.numeric(umap_df$cluster_kmeans), centrotypes="centroids")
val_dbi_kmeans <- dbi_kmeans_res$DB

# B2. DBI DBSCAN
# PENTING: Untuk DBI yang adil, kita harus membuang NOISE (Cluster 0)
# Karena noise bukan cluster, jika dihitung akan merusak nilai DBI.
clean_idx <- which(umap_df$cluster_dbscan != "0") # Ambil yang bukan noise

if(length(clean_idx) > 0 && length(unique(umap_df$cluster_dbscan[clean_idx])) > 1) {
  # Hitung DBI hanya untuk data yang ter-cluster
  dbi_dbscan_res <- index.DB(umap_df[clean_idx, 1:2], 
                             as.numeric(umap_df$cluster_dbscan[clean_idx]), 
                             centrotypes="centroids")
  val_dbi_dbscan <- dbi_dbscan_res$DB
} else {
  val_dbi_dbscan <- NA
  print("Warning: DBSCAN tidak memiliki cukup cluster valid untuk hitung DBI.")
}

# ------------------------------------------------------------
# BAGIAN C: ANALISIS NOISE (OUTLIER) & CAKUPAN
# ------------------------------------------------------------
print("--- 3. Analisis Cakupan & Outlier ---")

total_prov <- nrow(umap_df)
noise_count <- sum(umap_df$cluster_dbscan == "0")
noise_percent <- (noise_count / total_prov) * 100

# Identifikasi Provinsi yang jadi Noise (Penting untuk Penanggulangan Kemiskinan)
provinsi_noise <- umap_df$provinsi[umap_df$cluster_dbscan == "0"]

# ------------------------------------------------------------
# BAGIAN D: TABEL RANGKUMAN FINAL
# ------------------------------------------------------------
comparison_table <- data.frame(
  Metrik = c("Silhouette Score (Higher is Better)", 
             "Davies-Bouldin Index (Lower is Better)", 
             "Jumlah Cluster Terbentuk", 
             "Jumlah Noise (Outlier)", 
             "Persentase Data Terbuang (Noise)"),
  
  K_Means = c(round(avg_sil_kmeans, 4), 
              round(val_dbi_kmeans, 4), 
              length(unique(umap_df$cluster_kmeans)), 
              0, 
              "0%"),
  
  DBSCAN = c(round(avg_sil_dbscan, 4), 
             ifelse(is.na(val_dbi_dbscan), "NA", round(val_dbi_dbscan, 4)), 
             length(unique(umap_df$cluster_dbscan)) , # Dikurangi 1 karena noise bukan cluster
             noise_count, 
             paste0(round(noise_percent, 2), "%"))
)

print("=== TABEL PERBANDINGAN PERFORMA ===")
print(comparison_table)

print("=== DAFTAR PROVINSI OUTLIER (DBSCAN NOISE) ===")
if(length(provinsi_noise) > 0) {
  print(paste(provinsi_noise, collapse = ", "))
  print("INTERPRETASI: Provinsi di atas memiliki karakteristik kemiskinan yang SANGAT UNIK/BERBEDA dari pola umum nasional.")
} else {
  print("Tidak ada provinsi yang dianggap outlier.")
}


# ============================================================
# 6. PROFILING KARAKTERISTIK CLUSTER (DBSCAN FINAL)
# ============================================================
print(">>> Membuat Profiling Heatmap untuk Pemenang (DBSCAN)...")

# 1. Siapkan Data
# Kita gunakan data_num (data asli sebelum scaling) agar angkanya mudah dibaca manusia
# (Misal: Pengeluaran dalam Rupiah, bukan angka desimal aneh)
data_dbscan_profile <- data_num
data_dbscan_profile$cluster <- umap_df$cluster_dbscan

# 2. Hitung Rata-rata setiap indikator per Cluster
summary_dbscan <- data_dbscan_profile %>%
  group_by(cluster) %>%
  summarise(across(everything(), mean))

# 3. Format Data untuk Heatmap
heatmap_matrix <- as.data.frame(summary_dbscan)
rownames(heatmap_matrix) <- paste("Cluster", heatmap_matrix$cluster)
heatmap_matrix$cluster <- NULL # Hapus kolom label agar isi matriks hanya angka

# 4. Visualisasi Heatmap
# scale = "column" penting agar perbedaan tinggi/rendah terlihat per variabel
pheatmap(
  heatmap_matrix,
  scale = "column",             # Normalisasi per kolom indikator
  cluster_rows = TRUE,          # Kelompokkan cluster yang mirip
  cluster_cols = TRUE,          # Kelompokkan variabel yang mirip
  display_numbers = TRUE,       # Tampilkan angkanya
  number_format = "%.2f",       # Format angka desimal
  fontsize_number = 9,
  main = "Karakteristik Kemiskinan Provinsi per Cluster (DBSCAN)",
  color = colorRampPalette(c("#4575b4", "white", "#d73027"))(100), # Biru(Rendah) - Merah(Tinggi)
  angle_col = 45
)

# ============================================================
# 7. DAFTAR ANGGOTA CLUSTER (UNTUK JURNAL)
# ============================================================
print(">>> Menampilkan Daftar Provinsi per Cluster DBSCAN...")

list_provinsi <- split(umap_df$provinsi, umap_df$cluster_dbscan)

# Loop print agar rapi
for(cl in names(list_provinsi)) {
  cat("\n------------------------------------------------\n")
  cat(paste("CLUSTER", cl, "(Jumlah:", length(list_provinsi[[cl]]), "Provinsi)\n"))
  cat("------------------------------------------------\n")
  print(paste(list_provinsi[[cl]], collapse = ", "))
}

# jurnal hasil data science https://docs.google.com/document/d/14mA44bm0Gh6kQ_2k0WrfppakwmDzhRRd/edit?usp=sharing&ouid=104243006301926771570&rtpof=true&sd=true
