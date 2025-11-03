import os
import base64
import json
import logging

from django.conf import settings
from django.http import JsonResponse, HttpResponse, HttpResponseBadRequest
from django.shortcuts import render, redirect, get_object_or_404
from django.views.decorators.csrf import csrf_exempt

from django.contrib.auth.hashers import make_password, check_password

from .models import Login, UserProfile, Post, Comment, Complaint, FriendRequest, Chat

# ML imports (optional) -- load only if available
ML_MODEL = None
TOKENIZER = None
MAX_SEQ_LEN = 100

try:
    import tensorflow as tf
    from tensorflow.keras.models import load_model
    from tensorflow.keras.preprocessing.sequence import pad_sequences
    from tensorflow.keras.preprocessing.text import tokenizer_from_json

    # model/tokenizer paths (place your artifacts here)
    MODEL_DIR = os.path.join(settings.BASE_DIR, 'myapp', 'models')
    MODEL_PATH = os.path.join(MODEL_DIR, 'cyberbullying_model')  # saved model directory or file
    TOKENIZER_PATH = os.path.join(MODEL_DIR, 'tokenizer.json')

    if os.path.exists(MODEL_PATH):
        try:
            ML_MODEL = load_model(MODEL_PATH)
            logging.info("ML model loaded from %s", MODEL_PATH)
        except Exception as e:
            logging.warning("Could not load full model from %s: %s", MODEL_PATH, e)
            ML_MODEL = None

    if os.path.exists(TOKENIZER_PATH):
        with open(TOKENIZER_PATH, 'r', encoding='utf-8') as f:
            tok_json = f.read()
            TOKENIZER = tokenizer_from_json(tok_json)
            logging.info("Tokenizer loaded from %s", TOKENIZER_PATH)
except Exception as e:
    logging.warning("TensorFlow or tokenizer not available: %s", e)
    ML_MODEL = None
    TOKENIZER = None


def _save_base64_image(base64_str: str, subdir: str = '') -> str:
    """
    Save a base64-encoded image to MEDIA_ROOT and return the relative URL path (e.g., /media/xxx.jpg).
    """
    if not base64_str:
        return None
    try:
        # normalize: if data:<mime>;base64,xxxxx
        if ',' in base64_str:
            base64_str = base64_str.split(',', 1)[1]

        data = base64.b64decode(base64_str)
    except Exception as e:
        logging.exception("Invalid base64 image data")
        return None

    os.makedirs(settings.MEDIA_ROOT, exist_ok=True)
    filename = f"{int(__import__('time').time() * 1000)}.jpg"
    if subdir:
        dirpath = os.path.join(settings.MEDIA_ROOT, subdir)
        os.makedirs(dirpath, exist_ok=True)
        filepath = os.path.join(dirpath, filename)
        media_url = f"{settings.MEDIA_URL}{subdir}/{filename}"
    else:
        filepath = os.path.join(settings.MEDIA_ROOT, filename)
        media_url = f"{settings.MEDIA_URL}{filename}"

    with open(filepath, "wb") as fh:
        fh.write(data)

    return media_url


def _predict_bullying(text: str) -> str:
    """
    Returns "Bullying Words" or "Not Bullying".
    If ML_MODEL or TOKENIZER are missing, default to "Not Bullying".
    """
    if not ML_MODEL or not TOKENIZER:
        return "Not Bullying"

    seq = TOKENIZER.texts_to_sequences([text])
    padded = pad_sequences(seq, maxlen=MAX_SEQ_LEN, padding='post', truncating='post')
    pred = ML_MODEL.predict(padded)
    # pred shape depends on model; assume sigmoid single output
    score = float(pred[0][0]) if hasattr(pred[0], '__len__') else float(pred[0])
    return "Bullying Words" if score >= 0.5 else "Not Bullying"


@csrf_exempt
def userlogin(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)
    username = request.POST.get('username') or request.POST.get('user') or ''
    password = request.POST.get('password') or request.POST.get('psw') or ''
    try:
        log = Login.objects.get(username=username)
    except Login.DoesNotExist:
        return JsonResponse({'status': 'not ok'})
    if check_password(password, log.password):
        if log.type == 'user':
            return JsonResponse({'status': 'ok', 'lid': str(log.id)})
        else:
            return JsonResponse({'status': 'not ok'})
    else:
        return JsonResponse({'status': 'not ok'})


@csrf_exempt
def signup_post(request):
    """
    Expected form-data:
     - name, email, gender, phone, dob, place, district, state, pincode, photo (base64), password
    """
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)

    email = request.POST.get('email')
    password = request.POST.get('password') or request.POST.get('confirmpassword')
    name = request.POST.get('name', '')
    if not email or not password:
        return JsonResponse({'status': 'error', 'message': 'email and password required'}, status=400)

    if Login.objects.filter(username=email).exists():
        return JsonResponse({'status': 'error', 'message': 'email already registered'}, status=400)

    hashed = make_password(password)
    login = Login.objects.create(username=email, password=hashed, type='user')

    # Save profile
    image_base64 = request.POST.get('photo', '')
    photo_url = _save_base64_image(image_base64, subdir='profile_photos') if image_base64 else None

    profile = UserProfile.objects.create(
        login=login,
        name=name,
        email=email,
        gender=request.POST.get('gender', ''),
        phone=request.POST.get('phone', ''),
        place=request.POST.get('place', ''),
        post=request.POST.get('post', ''),
        district=request.POST.get('district', ''),
        state=request.POST.get('state', ''),
        pin=request.POST.get('pincode', ''),
        photo=photo_url.replace(settings.MEDIA_URL, '') if photo_url else None
    )

    return JsonResponse({'status': 'ok', 'lid': str(login.id)})


@csrf_exempt
def user_viewprofile(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)
    lid = request.POST.get('lid')
    try:
        login = Login.objects.get(id=lid)
        profile = login.profile
    except Exception:
        return JsonResponse({'status': 'error', 'message': 'user not found'}, status=404)

    data = {
        'status': 'ok',
        'name': profile.name,
        'gender': profile.gender,
        'dob': profile.dob.isoformat() if profile.dob else '',
        'email': profile.email,
        'photo': profile.photo.url if getattr(profile.photo, 'url', None) else profile.photo or '',
        'phone': profile.phone,
        'place': profile.place,
        'post': profile.post,
        'pin': profile.pin,
        'state': profile.state,
        'district': profile.district,
    }
    return JsonResponse(data)


@csrf_exempt
def user_editprofile(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)
    lid = request.POST.get('lid')
    try:
        login = Login.objects.get(id=lid)
        profile = login.profile
    except Exception:
        return JsonResponse({'status': 'error', 'message': 'user not found'}, status=404)

    # Update fields
    profile.name = request.POST.get('name', profile.name)
    profile.email = request.POST.get('email', profile.email)
    profile.gender = request.POST.get('gender', profile.gender)
    profile.phone = request.POST.get('phone', profile.phone)
    profile.place = request.POST.get('place', profile.place)
    profile.district = request.POST.get('district', profile.district)
    profile.state = request.POST.get('state', profile.state)
    profile.pin = request.POST.get('pin', profile.pin)
    dob = request.POST.get('dob', None)
    if dob:
        try:
            from datetime import datetime
            profile.dob = datetime.strptime(dob, '%Y-%m-%d').date()
        except Exception:
            pass

    image_b64 = request.POST.get('photo', '')
    if image_b64 and len(image_b64) > 10:
        photo_url = _save_base64_image(image_b64, subdir='profile_photos')
        if photo_url:
            # store path relative to MEDIA_ROOT; Django ImageField expects path relative to MEDIA_ROOT when assigned as string
            profile.photo = photo_url.replace(settings.MEDIA_URL, '')

    profile.save()
    # update username on login if email changed
    if login.username != profile.email:
        login.username = profile.email
        login.save()

    return JsonResponse({'status': 'ok'})


@csrf_exempt
def userchangepass(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)
    lid = request.POST.get('lid')
    cpass = request.POST.get('cpass')
    confpass = request.POST.get('confpass')
    try:
        login = Login.objects.get(id=lid)
    except Login.DoesNotExist:
        return JsonResponse({'status': 'no'})

    if check_password(cpass, login.password):
        login.password = make_password(confpass)
        login.save()
        return JsonResponse({'status': 'ok'})
    else:
        return JsonResponse({'status': 'no'})


@csrf_exempt
def useraddpost(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)
    lid = request.POST.get('lid')
    desc = request.POST.get('desc', '')
    photo_b64 = request.POST.get('photo', '')

    try:
        login = Login.objects.get(id=lid)
        user = login.profile
    except Exception:
        return JsonResponse({'status': 'error', 'message': 'user not found'}, status=404)

    photo_url = _save_base64_image(photo_b64, subdir='post_photos') if photo_b64 else None

    post = Post.objects.create(
        desc=desc,
        photo=photo_url.replace(settings.MEDIA_URL, '') if photo_url else None,
        user=user
    )

    return JsonResponse({'status': 'ok', 'post_id': post.id})


@csrf_exempt
def add_comment(request):
    """
    Expects: lid, postid, comment (text)
    Uses ML model to mark comment as Bullying/Not Bullying when model exists.
    """
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)
    lid = request.POST.get('lid')
    pid = request.POST.get('postid')
    comment_text = request.POST.get('comment', '')

    if not (lid and pid and comment_text):
        return JsonResponse({'status': 'error', 'message': 'lid, postid and comment required'}, status=400)
    try:
        login = Login.objects.get(id=lid)
        user = login.profile
        post = Post.objects.get(id=pid)
    except Exception:
        return JsonResponse({'status': 'error', 'message': 'invalid user or post'}, status=404)

    status = _predict_bullying(comment_text)
    from datetime import date
    comment_obj = Comment.objects.create(
        user=user,
        post=post,
        comments=comment_text,
        status=status,
        date=date.today()
    )
    return JsonResponse({'status': 'ok', 'comment_id': comment_obj.id, 'bullying_status': status})


@csrf_exempt
def view_ownpost(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)
    lid = request.POST.get('lid')
    try:
        login = Login.objects.get(id=lid)
        user = login.profile
    except Exception:
        return JsonResponse({'status': 'error', 'message': 'user not found'}, status=404)

    posts = user.posts.all().values('id', 'desc', 'date', 'photo')
    data = []
    for p in posts:
        photo = p['photo']
        if photo:
            photo = settings.MEDIA_URL + photo
        data.append({'id': p['id'], 'desc': p['desc'], 'date': str(p['date']), 'photo': photo})
    return JsonResponse({'status': 'ok', 'data': data})


@csrf_exempt
def viewpostothers(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)
    lid = request.POST.get('lid')
    from django.db.models import Q
    posts_qs = Post.objects.exclude(user__login__id=lid).select_related('user').order_by('-id')[:200]
    out = []
    for post in posts_qs:
        photo = post.photo.url if getattr(post.photo, 'url', None) else (settings.MEDIA_URL + post.photo) if post.photo else ''
        out.append({'id': post.id, 'photo': photo, 'desc': post.desc, 'date': str(post.date), 'name': post.user.name})
    return JsonResponse({'status': 'ok', 'data': out})


@csrf_exempt
def chat_send(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)
    from_id = request.POST.get('from_id')
    to_id = request.POST.get('to_id')
    msg = request.POST.get('message', '')
    try:
        c = Chat.objects.create(FROMID_id=from_id, TOID_id=to_id, message=msg)
        return JsonResponse({'status': 'ok', 'chat_id': c.id})
    except Exception as e:
        logging.exception("Chat send error")
        return JsonResponse({'status': 'error', 'message': 'could not send'}, status=500)


@csrf_exempt
def chat_view_and(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'POST required'}, status=400)
    from_id = request.POST.get('from_id')
    to_id = request.POST.get('to_id')
    data = []
    try:
        data1 = Chat.objects.filter(from_login__id=from_id, to_login__id=to_id).order_by('id')
        data2 = Chat.objects.filter(from_login__id=to_id, to_login__id=from_id).order_by('id')
        # union
        all_msgs = list(data1) + list(data2)
        for res in sorted(all_msgs, key=lambda x: x.id):
            data.append({'id': res.id, 'from': res.from_login.id, 'to': res.to_login.id, 'msg': res.message, 'date': str(res.date)})
        return JsonResponse({'status': 'ok', 'data': data})
    except Exception:
        logging.exception("chat_view error")
        return JsonResponse({'status': 'error', 'message': 'error fetching chat'}, status=500)
