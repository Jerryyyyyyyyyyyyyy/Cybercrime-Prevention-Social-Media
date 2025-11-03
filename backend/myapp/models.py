from django.db import models

class Login(models.Model):
    username = models.CharField(max_length=150, unique=True)
    password = models.CharField(max_length=128)  # hashed passwords expected
    TYPE_CHOICES = (('admin', 'Admin'), ('user', 'User'))
    type = models.CharField(max_length=10, choices=TYPE_CHOICES, default='user')

    def __str__(self):
        return f"{self.username} ({self.type})"

class UserProfile(models.Model):
    login = models.OneToOneField(Login, on_delete=models.CASCADE, related_name='profile')
    name = models.CharField(max_length=100)
    dob = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=20, blank=True)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True)
    place = models.CharField(max_length=200, blank=True)
    post = models.CharField(max_length=200, blank=True)
    state = models.CharField(max_length=100, blank=True)
    pin = models.CharField(max_length=20, blank=True)
    district = models.CharField(max_length=100, blank=True)
    photo = models.ImageField(upload_to='profile_photos/', null=True, blank=True)

    def __str__(self):
        return self.name

class FriendRequest(models.Model):
    STATUS_CHOICES = (('pending','Pending'), ('accepted','Accepted'), ('rejected','Rejected'))
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    from_user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='sent_requests')
    to_user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='received_requests')
    created_at = models.DateTimeField(auto_now_add=True)

class Post(models.Model):
    desc = models.CharField(max_length=500, blank=True)
    photo = models.ImageField(upload_to='post_photos/', null=True, blank=True)
    date = models.DateField(auto_now_add=True)
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='posts')

class Complaint(models.Model):
    complaint = models.TextField()
    reply = models.TextField(default="pending")
    status = models.CharField(max_length=50, default="pending")
    date = models.DateField(auto_now_add=True)
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='complaints')

class Comment(models.Model):
    comments = models.TextField()
    status = models.CharField(max_length=100, default="Not Bullying")
    date = models.DateField(auto_now_add=True)
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')

class Chat(models.Model):
    date = models.DateTimeField(auto_now_add=True)
    message = models.TextField()
    to_login = models.ForeignKey(Login, on_delete=models.CASCADE, related_name='chats_to')
    from_login = models.ForeignKey(Login, on_delete=models.CASCADE, related_name='chats_from')
