import os
import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.decomposition import LatentDirichletAllocation
from wordcloud import WordCloud
import matplotlib.pyplot as plt

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 1. transformation of the dataset (turn ind-skill level to ind level)
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

path_skills = (
    "E:/__RA/02MANAGERS/Paper Managers/Data/01RawData/01MNEData/SkillsInput.dta"
)
path_output_data = (
    "E:/__RA/02MANAGERS/Paper Managers/Data/02TempData/temp_SkillsAfterLDA.dta"
)
path_output_fig = "E:/__RA/02MANAGERS/Paper Managers/Results"

data = pd.read_stata(path_skills)

skills_ind = data[["IDlse", "Skills"]].copy()
skills_ind = skills_ind.dropna()
skills_ind.dtypes
skills_ind["IDlse"] = skills_ind["IDlse"].astype(np.int64)
skills_ind["Skills"] = skills_ind["Skills"].astype("string")
skills_ind

skills_combined = (
    skills_ind.groupby("IDlse")["Skills"]
    .agg(lambda x: ", ".join(x))
    .reset_index()
)

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 2. LDA analysis on the Skills variable
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

# Preprocess the skills data
vectorizer = CountVectorizer()
skills_matrix = vectorizer.fit_transform(skills_combined["Skills"])

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-1. Fit LDA model and get topic distributions for each individual
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?


#!! Function to fit LDA model and get topic distributions
def fit_lda_and_get_topics(n_topics, skills_matrix):
    lda_model = LatentDirichletAllocation(
        n_components=n_topics, random_state=42
    )
    lda_model.fit(skills_matrix)
    topic_distributions = lda_model.transform(skills_matrix)

    for i in range(n_topics):
        skills_combined[f"Topic{i+1}_{n_topics}"] = topic_distributions[:, i]

    return lda_model


#!! Fit the LDA model with 2 topics
lda_2_topics = fit_lda_and_get_topics(2, skills_matrix)

#!! Fit the LDA model with 3 topics
lda_3_topics = fit_lda_and_get_topics(3, skills_matrix)

#!! Fit the LDA model with 5 topics
lda_5_topics = fit_lda_and_get_topics(5, skills_matrix)

#!! Fit the LDA model with 3 topics
skills_combined[
    [
        "IDlse",
        "Topic1_2",
        "Topic2_2",
        "Topic1_3",
        "Topic2_3",
        "Topic3_3",
        "Topic1_5",
        "Topic2_5",
        "Topic3_5",
        "Topic4_5",
        "Topic5_5",
    ]
].to_stata(path_output_data)

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 3. Describe the resulting topics
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??


# Extract the top words for each topic
def get_top_words(lda_model, feature_names, n_top_words):
    top_words = {}
    for topic_idx, topic in enumerate(lda_model.components_):
        top_words[f"Topic {topic_idx + 1}"] = [
            feature_names[i] for i in topic.argsort()[: -n_top_words - 1 : -1]
        ]
    return top_words


n_top_words = 50
feature_names = vectorizer.get_feature_names_out()

# Get top words for 2-topic model
top_words_2_topics = get_top_words(lda_2_topics, feature_names, n_top_words)

# Get top words for 3-topic model
top_words_3_topics = get_top_words(lda_3_topics, feature_names, n_top_words)

# Get top words for 3-topic model
top_words_3_topics_unlimited = get_top_words(lda_3_topics, feature_names, 1000)

# Get top words for 5-topic model
top_words_5_topics = get_top_words(lda_5_topics, feature_names, n_top_words)


# Function to generate word clouds for topics
def generate_word_clouds(top_words, filepath, model_type):
    for topic, words in top_words.items():
        wordcloud = WordCloud(
            width=800, height=400, background_color="white"
        ).generate(" ".join(words))
        plt.figure()
        plt.imshow(wordcloud, interpolation="bilinear")
        plt.axis("off")
        plt.title(topic)
        final_file_path = os.path.join(filepath, f"{model_type}_{topic}.png")
        plt.savefig(final_file_path)
        plt.show()
        plt.close()


# Generate word clouds for 2-topic model
generate_word_clouds(top_words_2_topics, path_output_fig, "LDA2")

# Generate word clouds for 3-topic model
generate_word_clouds(top_words_3_topics, path_output_fig, "LDA3")

# Generate word clouds for 3-topic model
generate_word_clouds(
    top_words_3_topics_unlimited, path_output_fig, "LDA3Unlimited"
)

# Generate word clouds for 5-topic model
generate_word_clouds(top_words_5_topics, path_output_fig, "LDA5")
