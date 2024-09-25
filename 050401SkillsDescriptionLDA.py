#! python3

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 0. configuration
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

import os
import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.decomposition import LatentDirichletAllocation
from wordcloud import WordCloud
import matplotlib.pyplot as plt

path_skills = (
    "E:/__RA/02MANAGERS/Paper Managers/Data/01RawData/01MNEData/SkillsInput.dta"
)
path_output_data = (
    "E:/__RA/02MANAGERS/Paper Managers/Data/02TempData/temp_SkillsAfterLDA.dta"
)
path_output_fig = "E:/__RA/02MANAGERS/Paper Managers/Results"

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 1. transformation of the dataset (turn ind-skill level to ind level)
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

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
# -? s-2-1. Fit 3-topic LDA model
# -?        and get topic distributions for each individual
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?


#!! A function to fit LDA model and get topic distributions
def fit_lda_and_get_topics(n_topics, skills_matrix):
    lda_model = LatentDirichletAllocation(
        n_components=n_topics, random_state=42
    )
    lda_model.fit(skills_matrix)
    topic_distributions = lda_model.transform(skills_matrix)

    for i in range(n_topics):
        skills_combined[f"Topic{i+1}_{n_topics}"] = topic_distributions[:, i]

    return lda_model


#!! Fit the LDA model with 3 topics
lda_3_topics = fit_lda_and_get_topics(3, skills_matrix)

#!! Fit the LDA model with 3 topics
skills_combined[
    [
        "IDlse",
        "Topic1_3",
        "Topic2_3",
        "Topic3_3",
    ]
].to_stata(path_output_data)

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-2. Describe the resulting topic 
# -?        (word distribution) using word cloud
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?


# !! A function to extract the top words for each topic
def get_top_words(model, feature_names, n_top_words):
    top_words = {}
    for topic_idx, topic in enumerate(model.components_):
        top_words_for_topic = {
            feature_names[i]: topic[i]
            for i in topic.argsort()[: -n_top_words - 1 : -1]
        }
        top_words[f"Topic {topic_idx + 1}"] = top_words_for_topic
    return top_words


# !! A function to generate word clouds for topics
def generate_word_clouds(top_words, filepath, model_type):
    for topic, words_probs in top_words.items():
        wordcloud = WordCloud(
            width=800, height=400, background_color="white"
        ).generate_from_frequencies(words_probs)
        plt.figure()
        plt.imshow(wordcloud, interpolation="bilinear")
        plt.axis("off")
        plt.title(topic)
        final_file_path = os.path.join(filepath, f"{model_type}_{topic}.png")
        plt.savefig(final_file_path)
        plt.show()
        plt.close()


# !! Get top words for 3-topic model
feature_names = vectorizer.get_feature_names_out()
top_words_3_topics_50 = get_top_words(lda_3_topics, feature_names, 50)
top_words_3_topics_1000 = get_top_words(lda_3_topics, feature_names, 1000)

# !! Generate word clouds for 3-topic model
generate_word_clouds(top_words_3_topics_50, path_output_fig, "LDA3_50Words")
generate_word_clouds(top_words_3_topics_1000, path_output_fig, "LDA3_1000Words")

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 3. Test 2- and 5-Topic LDA analysis
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??


#!! Fit the LDA model with 2 and 5 topics
lda_2_topics = fit_lda_and_get_topics(2, skills_matrix)
lda_5_topics = fit_lda_and_get_topics(5, skills_matrix)

# !! Get top words for 2- and 5-topic model
top_words_2_topics_1000 = get_top_words(lda_2_topics, feature_names, 1000)
top_words_5_topics_1000 = get_top_words(lda_5_topics, feature_names, 1000)

# !! Generate word clouds for 2- and 5-topic model
generate_word_clouds(top_words_2_topics_1000, path_output_fig, "LDA2_1000Words")
generate_word_clouds(top_words_5_topics_1000, path_output_fig, "LDA5_1000Words")
