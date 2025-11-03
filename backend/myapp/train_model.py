# train_model.py
import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from sklearn.model_selection import train_test_split
import json
import os

# 1. Load your dataset
df = pd.read_csv('backend/static/cyberbullying_tweets.csv')
texts = df['tweet_text'].values
labels = (df['cyberbullying_type'] != 'not_cyberbullying').astype(int).values  # 1 = bullying

# 2. Preprocess
def clean_text(text):
    import re
    text = re.sub(r'[^a-zA-Z\s]', '', text.lower())
    return text

texts = [clean_text(t) for t in texts]

# 3. Tokenize
vocab_size = 2000
tokenizer = Tokenizer(num_words=vocab_size, oov_token="<OOV>")
tokenizer.fit_on_texts(texts)

# Save tokenizer
with open('backend/myapp/tokenizer.json', 'w') as f:
    json.dump(tokenizer.to_json(), f)

sequences = tokenizer.texts_to_sequences(texts)
padded = pad_sequences(sequences, maxlen=100, padding='post', truncating='post')

# 4. Split data
X_train, X_test, y_train, y_test = train_test_split(padded, labels, test_size=0.2, random_state=42)

# 5. Build Bi-LSTM Model
model = tf.keras.Sequential([
    tf.keras.layers.Embedding(vocab_size, 64, input_length=100),
    tf.keras.layers.Bidirectional(tf.keras.layers.LSTM(64, dropout=0.2, recurrent_dropout=0.2)),
    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(1, activation='sigmoid')
])

model.compile(loss='binary_crossentropy', optimizer='adam', metrics=['accuracy'])

# 6. Train
model.fit(X_train, y_train, epochs=10, validation_data=(X_test, y_test), batch_size=32)

# 7. Save the trained model weights
model.save_weights('backend/myapp/cyberbullying-bdlstm.h5')

print("Model trained and saved as cyberbullying-bdlstm.h5")