"""
Test cases for the 'myapp' application.

This file contains unit tests for:
- Models (Login, User, Post, Comments, etc.)
- Views (login, registration, AI detection)
- AI Model integration
- Database integrity

Run with: python manage.py test myapp
"""

from django.test import TestCase
from django.urls import reverse
from django.contrib.auth import get_user_model
from .models import Login, User, Post, Comments, Complaint, Chat
from datetime import date
import json
import os

class ModelTests(TestCase):
    def setUp(self):
        # Create a login entry
        self.login = Login.objects.create(
            username="testuser",
            password="testpass123",
            type="user"
        )
        # Create a user
        self.user = User.objects.create(
            name="Test User",
            dob="1995-01-01",
            gender="Male",
            email="test@example.com",
            phone="9876543210",
            place="Kochi",
            post="Post Office",
            state="Kerala",
            pin="682001",
            district="Ernakulam",
            photo="media/test.jpg",
            LOGIN=self.login
        )

    def test_login_creation(self):
        """Test Login model creation"""
        self.assertEqual(self.login.username, "testuser")
        self.assertEqual(self.login.type, "user")
        self.assertTrue(self.login.password)  # Password should not be empty

    def test_user_creation(self):
        """Test User model creation and foreign key"""
        self.assertEqual(self.user.name, "Test User")
        self.assertEqual(self.user.LOGIN, self.login)
        self.assertIn("example.com", self.user.email)

    def test_post_creation(self):
        """Test Post model"""
        post = Post.objects.create(
            desc="This is a test post",
            photo="media/post.jpg",
            date=date.today().strftime("%Y-%m-%d"),
            USER=self.user
        )
        self.assertEqual(post.desc, "This is a test post")
        self.assertEqual(post.USER, self.user)

    def test_comments_with_ai_status(self):
        """Test Comments model with AI status"""
        post = Post.objects.create(desc="Post", photo="", date="2025-04-01", USER=self.user)
        comment = Comments.objects.create(
            comments="you are ugly",
            date="2025-04-01",
            USER=self.user,
            POST=post
        )
        # AI should flag this as bullying
        self.assertIn("bullying", comment.status.lower())

    def test_friend_request(self):
        """Test Friendrequest model"""
        friend = User.objects.create(name="Friend", email="friend@example.com", LOGIN=self.login)
        from myapp.models import Friendrequest
        request = Friendrequest.objects.create(
            status="pending",
            USER=self.user,
            TOUSER=friend
        )
        self.assertEqual(request.status, "pending")


class ViewTests(TestCase):
    def setUp(self):
        self.login = Login.objects.create(username="admin", password="admin123", type="admin")
        self.client.login(username="admin", password="admin123")

    def test_login_view(self):
        """Test login view returns 200"""
        response = self.client.get(reverse('myapp:login'))
        self.assertEqual(response.status_code, 200)

    def test_user_registration(self):
        """Test user registration via API"""
        data = {
            "name": "New User",
            "email": "new@example.com",
            "phone": "9999999999",
            "password": "pass123"
        }
        response = self.client.post(reverse('myapp:register'), data)
        self.assertEqual(response.status_code, 200)
        self.assertTrue(User.objects.filter(email="new@example.com").exists())


class AITestCase(TestCase):
    """Test AI model loading and prediction"""

    def test_model_exists(self):
        """Check if cyberbullying-bdlstm.h5 exists"""
        model_path = os.path.join(os.path.dirname(__file__), 'cyberbullying-bdlstm.h5')
        self.assertTrue(os.path.exists(model_path), "AI model file is missing!")

    def test_tokenizer_exists(self):
        """Check if tokenizer.json exists"""
        tokenizer_path = os.path.join(os.path.dirname(__file__), 'tokenizer.json')
        self.assertTrue(os.path.exists(tokenizer_path), "Tokenizer file is missing!")

    def test_prediction_logic(self):
        """Simulate AI prediction logic from views.py"""
        from tensorflow.keras.preprocessing.text import tokenizer_from_json
        from tensorflow.keras.preprocessing.sequence import pad_sequences
        import tensorflow as tf
        import numpy as np

        tokenizer_path = os.path.join(os.path.dirname(__file__), 'tokenizer.json')
        model_path = os.path.join(os.path.dirname(__file__), 'cyberbullying-bdlstm.h5')

        with open(tokenizer_path, 'r') as f:
            tokenizer = tokenizer_from_json(f.read())

        model = tf.keras.Sequential([
            tf.keras.layers.Embedding(2000, 64, input_length=100),
            tf.keras.layers.Bidirectional(tf.keras.layers.LSTM(64)),
            tf.keras.layers.Dense(1, activation='sigmoid')
        ])
        model.load_weights(model_path)

        # Test bullying phrase
        text = "you are stupid"
        seq = tokenizer.texts_to_sequences([text])
        padded = pad_sequences(seq, maxlen=100)
        pred = model.predict(padded)[0][0]
        self.assertGreater(pred, 0.5)  # Should predict bullying

        # Test normal phrase
        text2 = "nice photo"
        seq2 = tokenizer.texts_to_sequences([text2])
        padded2 = pad_sequences(seq2, maxlen=100)
        pred2 = model.predict(padded2)[0][0]
        self.assertLess(pred2, 0.5)  # Should predict not bullying


# Run all tests
if __name__ == "__main__":
    import unittest
    unittest.main()