from django.contrib import admin
from .models import Login, UserProfile, FriendRequest, Post, Complaint, Comment, Chat

admin.site.register(Login)
admin.site.register(UserProfile)
admin.site.register(FriendRequest)
admin.site.register(Post)
admin.site.register(Complaint)
admin.site.register(Comment)
admin.site.register(Chat)
