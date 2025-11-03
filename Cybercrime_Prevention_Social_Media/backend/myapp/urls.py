"""
URL configuration for the 'myapp' application.

All routes under /myapp/ are defined here:
- Admin Web Interface (HTML)
- Flutter Mobile API (JSON)
- AI Model Endpoints
- File Uploads (media)
"""

from django.urls import path
from . import views

app_name = 'myapp'

urlpatterns = [
    # ===================================================================
    # 1. ADMIN WEB INTERFACE (HTML Templates)
    # ===================================================================
    path('login/', views.login, name='login'),
    path('login_post/', views.login_post, name='login_post'),
    path('logout/', views.logout, name='logout'),
    path('index/', views.index, name='index'),
    path('viewuser/', views.viewuser, name='viewuser'),
    path('viewcomp/', views.viewcomp, name='viewcomp'),
    path('view_post/', views.view_post, name='view_post'),
    path('changepass/', views.changepass, name='changepass'),
    path('changepass_post/', views.changepass_post, name='changepass_post'),
    path('reply/<int:id>/', views.reply, name='reply'),
    path('block_user/<int:id>/', views.block_user, name='block_user'),
    path('unblock_user/<int:id>/', views.unblock_user, name='unblock_user'),

    # ===================================================================
    # 2. FLUTTER MOBILE APP API (JSON Responses)
    # ===================================================================
    path('register/', views.register, name='register'),
    path('userlogin/', views.userlogin, name='userlogin'),
    path('viewprofile/', views.viewprofile, name='viewprofile'),
    path('editprofile/', views.editprofile, name='editprofile'),
    path('add_post/', views.add_post, name='add_post'),
    path('view_post_user/', views.view_post_user, name='view_post_user'),
    path('view_comments/<int:id>/', views.view_comments, name='view_comments'),
    path('add_comment/', views.add_comment, name='add_comment'),
    path('send_complaint/', views.send_complaint, name='send_complaint'),
    path('view_reply/', views.view_reply, name='view_reply'),
    path('change_password/', views.change_password, name='change_password'),
    path('view_friends/', views.view_friends, name='view_friends'),
    path('view_friend_requests/', views.view_friend_requests, name='view_friend_requests'),
    path('send_friend_request/', views.send_friend_request, name='send_friend_request'),
    path('accept_friend_request/<int:id>/', views.accept_friend_request, name='accept_friend_request'),
    path('reject_friend_request/<int:id>/', views.reject_friend_request, name='reject_friend_request'),
    path('chat_view/<int:id>/', views.chat_view, name='chat_view'),
    path('chat_send/', views.chat_send, name='chat_send'),

    # ===================================================================
    # 3. AI & UTILITY ENDPOINTS
    # ===================================================================
    path('predict_cyberbullying/', views.predict_cyberbullying, name='predict_cyberbullying'),
    path('face_login/', views.face_login, name='face_login'),
    path('imei_login/', views.imei_login, name='imei_login'),
]