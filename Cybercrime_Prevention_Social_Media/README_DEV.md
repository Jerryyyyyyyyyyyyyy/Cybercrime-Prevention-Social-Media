# Dev setup (backend)

1. create venv and install:
   python -m venv venv
   source venv/bin/activate        # Linux/Mac
   venv\Scripts\activate.bat       # Windows
   pip install -r requirements.txt

2. Prepare nltk stopwords (if using NLP code):
   python -c "import nltk; nltk.download('stopwords')"

3. Put ML artifacts (if you want bullying detection):
   backend/myapp/models/
     - cyberbullying_model/        # saved model (use tf.keras.models.save())
     - tokenizer.json

   or:
     - cyberbullying_model.h5      # if you prefer single H5 file
     - tokenizer.json

4. Migrate and run:
   cd backend
   python manage.py makemigrations
   python manage.py migrate
   python manage.py createsuperuser
   python manage.py runserver 0.0.0.0:8000

5. Flutter app:
   - Set backend IP in app to <your-ip>:8000 and use the endpoints under /myapp/

Notes:
- This dev setup uses sqlite3 by default; to use MySQL, update `cyber/settings.py` and install `mysqlclient`.
- For production: disable DEBUG, use secure SECRET_KEY, hashed passwords are already used, but better to use Django's auth.User.
