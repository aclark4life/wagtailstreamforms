# Project Makefile
#
# A generic makefile for projects.
#
# https://github.com/project-makefile/project-makefile

# License
#
# Copyright 2016—2024 Jeffrey A. Clark (Alex)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# --------------------------------------------------------------------------------
# Variables
# --------------------------------------------------------------------------------

.DEFAULT_GOAL := git-commit-push

UNAME := $(shell uname)
RANDIR := $(shell openssl rand -base64 12 | sed 's/\///g')
TMPDIR := $(shell mktemp -d)

PROJECT_EMAIL := aclark@aclark.net
PROJECT_MAKEFILE := project.mk
PROJECT_NAME = project-makefile

ifneq ($(wildcard $(PROJECT_MAKEFILE)),)
    include $(PROJECT_MAKEFILE)
endif

REVIEW_EDITOR := subl

GIT_BRANCHES = `git branch -a \
	| grep remote  \
	| grep -v HEAD \
	| grep -v main \
	| grep -v master`
GIT_COMMIT_MESSAGE := "Update $(PROJECT_NAME)"
GIT_REV := `git rev-parse --short HEAD`

# --------------------------------------------------------------------------------
# More variables
# --------------------------------------------------------------------------------

define GIT_IGNORE
bin/
__pycache__
lib/
lib64
pyvenv.cfg
node_modules/
share/
static/
media/
.elasticbeanstalk/
dist/
endef

define CONTACT_PAGE_TEMPLATE
{% extends 'base.html' %}
{% load crispy_forms_tags static wagtailcore_tags %}
{% block content %}
        <h1>{{ page.title }}</h1>
        {{ page.intro|richtext }}
        <form action="{% pageurl page %}" method="POST">
            {% csrf_token %}
            {{ form.as_p }}
            <input type="submit">
        </form>
{% endblock %}
endef

define CONTACT_PAGE_MODEL
from django.db import models
from modelcluster.fields import ParentalKey
from wagtail.admin.panels import (
    FieldPanel, FieldRowPanel,
    InlinePanel, MultiFieldPanel
)
from wagtail.fields import RichTextField
from wagtail.contrib.forms.models import AbstractEmailForm, AbstractFormField


class FormField(AbstractFormField):
    page = ParentalKey('ContactPage', on_delete=models.CASCADE, related_name='form_fields')


class ContactPage(AbstractEmailForm):
    intro = RichTextField(blank=True)
    thank_you_text = RichTextField(blank=True)

    content_panels = AbstractEmailForm.content_panels + [
        FieldPanel('intro'),
        InlinePanel('form_fields', label="Form fields"),
        FieldPanel('thank_you_text'),
        MultiFieldPanel([
            FieldRowPanel([
                FieldPanel('from_address', classname="col6"),
                FieldPanel('to_address', classname="col6"),
            ]),
            FieldPanel('subject'),
        ], "Email"),
    ]

    class Meta:
        verbose_name = "Contact Page"
endef

define CONTACT_PAGE_LANDING
{% extends 'base.html' %}
{% block content %}<div class="container"><h1>Thank you!</h1></div>{% endblock %}
endef

define INTERNAL_IPS
INTERNAL_IPS = ["127.0.0.1",]
endef

define REACT_CONTEXT_INDEX
export { UserContextProvider as default } from './UserContextProvider';
endef

define REACT_CONTEXT_USER_PROVIDER
// UserContextProvider.js
import React, { createContext, useContext, useState } from 'react';
import PropTypes from 'prop-types';

const UserContext = createContext();

export const UserContextProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const login = () => {
    try {
      // Add logic to handle login, set isAuthenticated to true
      setIsAuthenticated(true);
    } catch (error) {
      console.error('Login error:', error);
      // Handle error, e.g., show an error message to the user
    }
  };

  const logout = () => {
    try {
      // Add logic to handle logout, set isAuthenticated to false
      setIsAuthenticated(false);
    } catch (error) {
      console.error('Logout error:', error);
      // Handle error, e.g., show an error message to the user
    }
  };

  return (
    <UserContext.Provider value={{ isAuthenticated, login, logout }}>
      {children}
    </UserContext.Provider>
  );
};

UserContextProvider.propTypes = {
  children: PropTypes.node.isRequired,
};

export const useUserContext = () => {
  const context = useContext(UserContext);

  if (!context) {
    throw new Error('useUserContext must be used within a UserContextProvider');
  }

  return context;
};

// Add PropTypes for the return value of useUserContext
useUserContext.propTypes = {
  isAuthenticated: PropTypes.bool.isRequired,
  login: PropTypes.func.isRequired,
  logout: PropTypes.func.isRequired,
};
endef


define COMPONENT_USER_MENU
// UserMenu.js
import React from 'react';
import PropTypes from 'prop-types';

function handleLogout() {
    window.location.href = '/accounts/logout';
}

const UserMenu = ({ isAuthenticated, isSuperuser, textColor }) => {
  return (
    <div> 
      {isAuthenticated ? (
        <li className="nav-item dropdown">
          <a className="nav-link dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
            User Menu
          </a>
          <ul className="dropdown-menu">
            <li><a className="dropdown-item" href="/user/profile">Profile</a></li>
            {isSuperuser ? (
              <>
                <li><hr className="dropdown-divider"></hr></li>
                <li><a className="dropdown-item" href="/django" target="_blank">Django admin</a></li>
                <li><a className="dropdown-item" href="/wagtail" target="_blank">Wagtail admin</a></li>
                <li><a className="dropdown-item" href="/api" target="_blank">Django REST framework</a></li>
              </>
            ) : null}
            <li><hr className="dropdown-divider"></hr></li>
            <li><a className="dropdown-item" href="/accounts/logout">Logout</a></li>
          </ul>
        </li>
      ) : (
        <li className="nav-item">
          <a className={`nav-link text-$${textColor}`} href="/accounts/login">User Menu</a>
        </li>
      )}
    </div>
  );
};

UserMenu.propTypes = {
  isAuthenticated: PropTypes.bool.isRequired,
  isSuperuser: PropTypes.bool.isRequired,
  textColor: PropTypes.string,
};

export default UserMenu;
endef

define COMPONENT_CLOCK
// Via ChatGPT
import React, { useState, useEffect, useCallback, useRef } from 'react';
import PropTypes from 'prop-types';

const Clock = ({ color = '#fff' }) => {
  const [date, setDate] = useState(new Date());
  const [blink, setBlink] = useState(true);
  const timerID = useRef();

  const tick = useCallback(() => {
    setDate(new Date());
    setBlink(prevBlink => !prevBlink);
  }, []);

  useEffect(() => {
    timerID.current = setInterval(() => tick(), 1000);

    // Return a cleanup function to be run on component unmount
    return () => clearInterval(timerID.current);
  }, [tick]);

  const formattedDate = date.toLocaleDateString(undefined, {
    weekday: 'short',
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });

  const formattedTime = date.toLocaleTimeString(undefined, {
    hour: 'numeric',
    minute: 'numeric',
  });

  return (
    <> 
      <div style={{ animation: blink ? 'blink 1s infinite' : 'none' }}><span className='me-2'>{formattedDate}</span> {formattedTime}</div>
    </>
  );
};

Clock.propTypes = {
  color: PropTypes.string,
};

export default Clock;
endef

define FRONTEND_STYLES
// If you comment out code below, bootstrap will use red as primary color
// and btn-primary will become red

// $primary: red;

@import "~bootstrap/scss/bootstrap.scss";

.jumbotron {
  // should be relative path of the entry scss file
  background-image: url("../../vendors/images/sample.jpg");
  background-size: cover;
}

#theme-toggler-authenticated:hover {
    cursor: pointer; /* Change cursor to pointer on hover */
    color: #007bff; /* Change color on hover */
}

#theme-toggler-anonymous:hover {
    cursor: pointer; /* Change cursor to pointer on hover */
    color: #007bff; /* Change color on hover */
}
endef

define FRONTEND_APP
import React from 'react';
import { createRoot } from 'react-dom/client';
import 'bootstrap';
import '@fortawesome/fontawesome-free/js/fontawesome';
import '@fortawesome/fontawesome-free/js/solid';
import '@fortawesome/fontawesome-free/js/regular';
import '@fortawesome/fontawesome-free/js/brands';
import getDataComponents from '../dataComponents';
import UserContextProvider from '../context';
import * as components from '../components';
import "../styles/index.scss";
import "../styles/theme-blue.scss";
import "./config";

const { ErrorBoundary } = components;
const dataComponents = getDataComponents(components);
const container = document.getElementById('app');
const root = createRoot(container);
const App = () => (
    <ErrorBoundary>
      <UserContextProvider>
        {dataComponents}
      </UserContextProvider>
    </ErrorBoundary>
)
root.render(<App />);
endef

define BABELRC
{
  "presets": [
    [
      "@babel/preset-react",
    ],
    [
      "@babel/preset-env",
      {
        "useBuiltIns": "usage",
        "corejs": "3.0.0"
      }
    ]
  ],
  "plugins": [
    "@babel/plugin-syntax-dynamic-import",
    "@babel/plugin-transform-class-properties"
  ]
}
endef

define ESLINTRC
{
    "env": {
        "browser": true,
        "es2021": true,
        "node": true
    },
    "extends": [
        "eslint:recommended",
        "plugin:react/recommended"
    ],
    "overrides": [
        {
            "env": {
                "node": true
            },
            "files": [
                ".eslintrc.{js,cjs}"
            ],
            "parserOptions": {
                "sourceType": "script"
            }
        }
    ],
    "parserOptions": {
        "ecmaVersion": "latest",
        "sourceType": "module"
    },
    "plugins": [
        "react"
    ],
    "rules": {
        "no-unused-vars": "off"
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
}
endef

define BASE_TEMPLATE
{% load static wagtailcore_tags wagtailuserbar webpack_loader %}

<!DOCTYPE html>
<html lang="en" class="h-100" data-bs-theme="{{ request.user.user_theme_preference|default:'light' }}">
    <head>
        <meta charset="utf-8" />
        <title>
            {% block title %}
            {% if page.seo_title %}{{ page.seo_title }}{% else %}{{ page.title }}{% endif %}
            {% endblock %}
            {% block title_suffix %}
            {% wagtail_site as current_site %}
            {% if current_site and current_site.site_name %}- {{ current_site.site_name }}{% endif %}
            {% endblock %}
        </title>
        {% if page.search_description %}
        <meta name="description" content="{{ page.search_description }}" />
        {% endif %}
        <meta name="viewport" content="width=device-width, initial-scale=1" />

        {# Force all links in the live preview panel to be opened in a new tab #}
        {% if request.in_preview_panel %}
        <base target="_blank">
        {% endif %}

        {% stylesheet_pack 'app' %}

        {% block extra_css %}
        {# Override this in templates to add extra stylesheets #}
        {% endblock %}

        <style>
          .success {
              background-color: #d4edda;
              border-color: #c3e6cb;
              color: #155724;
          }
          .info {
              background-color: #d1ecf1;
              border-color: #bee5eb;
              color: #0c5460;
          }
          .warning {
              background-color: #fff3cd;
              border-color: #ffeeba;
              color: #856404;
          }
          .danger {
              background-color: #f8d7da;
              border-color: #f5c6cb;
              color: #721c24;
          }
        </style>
		{% include 'favicon.html' %}
		{% csrf_token %}
    </head>
    <body class="{% block body_class %}{% endblock %} d-flex flex-column h-100">
        <main class="flex-shrink-0">
            {% wagtailuserbar %}
            <div id="app"></div>
            {% include 'header.html' %}
            {% if messages %}
                <div class="messages">
                    {% for message in messages %}
                        <div class="alert {{ message.tags }} alert-dismissible fade show"
                             role="alert">
                            {{ message }}
                            <button type="button"
                                    class="btn-close"
                                    data-bs-dismiss="alert"
                                    aria-label="Close"></button>
                        </div>
                    {% endfor %}
                </div>
            {% endif %}
            {% block content %}{% endblock %}
		</main>
        {% include 'footer.html' %}
        {% include 'offcanvas.html' %}
        {% javascript_pack 'app' %}
        {% block extra_js %}
        {# Override this in templates to add extra javascript #}
        {% endblock %}
    </body>
</html>
endef

define FAVICON_TEMPLATE
{% load static %}
<link href="{% static 'wagtailadmin/images/favicon.ico' %}" rel="icon">
endef

define PRIVACY_PAGE_MODEL
from wagtail.models import Page
from wagtail.admin.panels import FieldPanel
from wagtailmarkdown.fields import MarkdownField


class PrivacyPage(Page):
    """
    A Wagtail Page model for the Privacy Policy page.
    """

    template = "privacy_page.html"

    body = MarkdownField()

    content_panels = Page.content_panels + [
        FieldPanel("body", classname="full"),
    ]

    class Meta:
        verbose_name = "Privacy Page"
endef

define PRIVACY_PAGE_TEMPLATE
{% extends 'base.html' %}
{% load wagtailmarkdown %}
{% block content %}<div class="container">{{ page.body|markdown }}</div>{% endblock %}
endef

define HOME_PAGE_MODEL
from django.db import models
from wagtail.models import Page
from wagtail.fields import RichTextField, StreamField
from wagtail import blocks
from wagtail.admin.panels import FieldPanel
from wagtail.images.blocks import ImageChooserBlock
from wagtail_color_panel.fields import ColorField
from wagtail_color_panel.edit_handlers import NativeColorPanel


class MarketingBlock(blocks.StructBlock):
    title = blocks.CharBlock(required=False, help_text='Enter the block title')
    content = blocks.RichTextBlock(required=False, help_text='Enter the block content')
    images = blocks.ListBlock(ImageChooserBlock(required=False), help_text="Select one or two images for column display. Select three or more images for carousel display.")
    image = ImageChooserBlock(required=False, help_text="Select one image for background display.")
    block_class = blocks.CharBlock(
        required=False,
        help_text='Enter a CSS class for styling the marketing block',
        classname='full title',
        default='vh-100 bg-secondary',
    )
    image_class = blocks.CharBlock(
        required=False,
        help_text='Enter a CSS class for styling the column display image(s)',
        classname='full title',
        default='img-thumbnail p-5',
    )
    layout_class = blocks.CharBlock(
        required=False,
        help_text='Enter a CSS class for styling the layout.',
        classname='full title',
        default='d-flex flex-row',
    )

    class Meta:
        icon = 'placeholder'
        template = 'blocks/marketing_block.html'


class HomePage(Page):
    template = 'home/home_page.html'  # Create a template for rendering the home page
    marketing_blocks = StreamField([
        ('marketing_block', MarketingBlock()),
    ], blank=True, null=True, use_json_field=True)
    content_panels = Page.content_panels + [
        FieldPanel('marketing_blocks'),
    ]

    class Meta:
        verbose_name = 'Home Page'
endef

define ALLAUTH_LAYOUT_BASE
{% extends 'base.html' %}
endef

define BLOCK_CAROUSEL
        <div id="carouselExampleCaptions" class="carousel slide">
            <div class="carousel-indicators">
                {% for image in block.value.images %}
                    <button type="button"
                            data-bs-target="#carouselExampleCaptions"
                            data-bs-slide-to="{{ forloop.counter0 }}"
                            {% if forloop.first %}class="active" aria-current="true"{% endif %}
                            aria-label="Slide {{ forloop.counter }}"></button>
                {% endfor %}
            </div>
            <div class="carousel-inner">
                {% for image in block.value.images %}
                    <div class="carousel-item {% if forloop.first %}active{% endif %}">
                        <img src="{{ image.file.url }}" class="d-block w-100" alt="...">
                        <div class="carousel-caption d-none d-md-block">
                            <h5>{{ image.title }}</h5>
                        </div>
                    </div>
                {% endfor %}
            </div>
            <button class="carousel-control-prev"
                    type="button"
                    data-bs-target="#carouselExampleCaptions"
                    data-bs-slide="prev">
                <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                <span class="visually-hidden">Previous</span>
            </button>
            <button class="carousel-control-next"
                    type="button"
                    data-bs-target="#carouselExampleCaptions"
                    data-bs-slide="next">
                <span class="carousel-control-next-icon" aria-hidden="true"></span>
                <span class="visually-hidden">Next</span>
            </button>
        </div>
endef

define BLOCK_MARKETING
{% load wagtailcore_tags %}
<div class="{{ self.block_class }}">
    {% if block.value.images.0 %}
        {% include 'blocks/carousel_block.html' %}
    {% else %}
        {{ self.title }}
        {{ self.content }}
    {% endif %}
</div>
endef

define HOME_PAGE_TEMPLATE
{% extends "base.html" %}
{% load wagtailcore_tags %}
{% block content %}
    <main class="{% block main_class %}{% endblock %}">
        {% for block in page.marketing_blocks %}
           {% include_block block %}
        {% endfor %}
    </main>
{% endblock %}
endef

define JENKINS_FILE
pipeline {
    agent any
    stages {
        stage('') {
            steps {
                echo ''
            }
        }
    }
}
endef

define AUTHENTICATION_BACKENDS
AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',
    'allauth.account.auth_backends.AuthenticationBackend',
]
endef

define SITEUSER_TEMPLATE
{% extends 'base.html' %}

{% block content %}
<div class="container">
  <h2>User Profile</h2>
  <p>Username: {{ user.username }}</p>
  <p>Theme: {{ user.user_theme_preference }}</p>
</div>
{% endblock %}
endef

define SITEUSER_VIEW
import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import JsonResponse
from django.utils.decorators import method_decorator
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from django.views.generic import DetailView

from siteuser.models import User


class UserProfileView(LoginRequiredMixin, DetailView):
    model = User
    template_name = "profile.html"

    def get_object(self, queryset=None):
        return self.request.user


@method_decorator(csrf_exempt, name="dispatch")
class UpdateThemePreferenceView(View):
    def post(self, request, *args, **kwargs):
        try:
            data = json.loads(request.body.decode("utf-8"))
            new_theme = data.get("theme")

            # Perform the logic to update the theme preference in your database or storage

            # Assuming you have a logged-in user, get the user instance
            user = request.user

            # Update the user's theme preference
            user.user_theme_preference = new_theme
            user.save()

            # For demonstration purposes, we'll just return the updated theme in the response
            response_data = {"theme": new_theme}

            return JsonResponse(response_data)
        except json.JSONDecodeError as e:
            return JsonResponse({"error": e}, status=400)

    def http_method_not_allowed(self, request, *args, **kwargs):
        return JsonResponse({"error": "Invalid request method"}, status=405)
endef

define SITEUSER_URLS
from django.urls import path
from .views import UserProfileView, UpdateThemePreferenceView

urlpatterns = [
    path('profile/', UserProfileView.as_view(), name='user-profile'),
    path('update_theme_preference/', UpdateThemePreferenceView.as_view(), name='update_theme_preference'),
]
endef

define BACKEND_URLS
from django.conf import settings
from django.urls import include, path
from django.contrib import admin

from wagtail.admin import urls as wagtailadmin_urls
from wagtail import urls as wagtail_urls
from wagtail.documents import urls as wagtaildocs_urls

from search import views as search_views

from rest_framework import routers, serializers, viewsets
from dj_rest_auth.registration.views import RegisterView

from siteuser.models import User

urlpatterns = [
    path('accounts/', include('allauth.urls')),
    path('django/', admin.site.urls),
    path('wagtail/', include(wagtailadmin_urls)),
    path('user/', include('siteuser.urls')),
]

if settings.DEBUG:
    from django.conf.urls.static import static
    from django.contrib.staticfiles.urls import staticfiles_urlpatterns

    # Serve static and media files from development server
    urlpatterns += staticfiles_urlpatterns()
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

    import debug_toolbar
    urlpatterns += [
        path("__debug__/", include(debug_toolbar.urls)),
    ]

# https://www.django-rest-framework.org/#example
class UserSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = User
        fields = ['url', 'username', 'email', 'is_staff']

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

router = routers.DefaultRouter()
router.register(r'users', UserViewSet)

urlpatterns += [
    path("api/", include(router.urls)),
    path("api/", include("rest_framework.urls", namespace="rest_framework")),
    path("api/", include("dj_rest_auth.urls")),
    path("api/register/", RegisterView.as_view(), name="register"),
]

urlpatterns += [
	path("hijack/", include("hijack.urls")),
]

urlpatterns += [
    # For anything not caught by a more specific rule above, hand over to
    # Wagtail's page serving mechanism. This should be the last pattern in
    # the list:
    path("", include(wagtail_urls)),

    # Alternatively, if you want Wagtail pages to be served from a subpath
    # of your site, rather than the site root:
    #    path("pages/", include(wagtail_urls)),
]
endef

define REST_FRAMEWORK
REST_FRAMEWORK = {
    # Use Django's standard `django.contrib.auth` permissions,
    # or allow read-only access for unauthenticated users.
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.DjangoModelPermissionsOrAnonReadOnly'
    ]
}
endef


define FRONTEND_APP_CONFIG
import '../utils/themeToggler.js';
endef

define WEBPACK_CONFIG_JS
const path = require('path');

module.exports = {
  mode: 'development',
  entry: './src/index.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
};
endef

define WEBPACK_INDEX_JS
const message = "Hello, World!";
console.log(message);
endef

define WEBPACK_INDEX_HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Hello, Webpack!</title>
</head>
<body>
  <script src="dist/bundle.js"></script>
</body>
</html>
endef

define REACT_PORTAL
// Via pwellever
import React from 'react';
import { createPortal } from 'react-dom';

const parseProps = data => Object.entries(data).reduce((result, [key, value]) => {
  if (value.toLowerCase() === 'true') {
    value = true;
  } else if (value.toLowerCase() === 'false') {
    value = false;
  } else if (value.toLowerCase() === 'null') {
    value = null;
  } else if (!isNaN(parseFloat(value)) && isFinite(value)) {
    // Parse numeric value
    value = parseFloat(value);
  } else if (
    (value[0] === '[' && value.slice(-1) === ']') || (value[0] === '{' && value.slice(-1) === '}')
  ) {
    // Parse JSON strings
    value = JSON.parse(value);
  }

  result[key] = value;
  return result;
}, {});

// This method of using portals instead of calling ReactDOM.render on individual components
// ensures that all components are mounted under a single React tree, and are therefore able
// to share context.

export default function getPageComponents (components) {
  const getPortalComponent = domEl => {
    // The element's "data-component" attribute is used to determine which component to render.
    // All other "data-*" attributes are passed as props.
    const { component: componentName, ...rest } = domEl.dataset;
    const Component = components[componentName];
    if (!Component) {
      console.error(`Component "$${componentName}" not found.`);
      return null;
    }
    const props = parseProps(rest);
    domEl.innerHTML = '';

    // eslint-disable-next-line no-unused-vars
    const { ErrorBoundary } = components;
    return createPortal(
      <ErrorBoundary>
        <Component {...props} />
      </ErrorBoundary>,
      domEl,
    );
  };

  return Array.from(document.querySelectorAll('[data-component]')).map(getPortalComponent);
}
endef

define FRONTEND_COMPONENTS
export { default as ErrorBoundary } from './ErrorBoundary';
export { default as UserMenu } from './UserMenu';
endef

define HTML_FOOTER
{% load wagtailcore_tags %}
  <footer class="footer mt-auto py-3 bg-body-tertiary pt-5 text-center text-small">
    {% wagtail_site as current_site %}
    <p class="mb-1">&copy; {% now "Y" %} {{ current_site.site_name|default:"Project Makefile" }}</p>
    <ul class="list-inline">
      <li class="list-inline-item"><a class="text-secondary text-decoration-none {% if request.path == '/' %}active{% endif %}" href="/">Home</a></li>
      {% for child in current_site.root_page.get_children %}
          <li class="list-inline-item"><a class="text-secondary text-decoration-none {% if request.path == child.url %}active{% endif %}" href="{{ child.url }}">{{ child }}</a></li>
      {% endfor %}
    </ul>
  </footer>
endef

define HTML_OFFCANVAS
{% load wagtailcore_tags %}
{% wagtail_site as current_site %}
<div class="offcanvas offcanvas-start bg-dark" tabindex="-1" id="offcanvasExample" aria-labelledby="offcanvasExampleLabel">
  <div class="offcanvas-header">
    <a class="offcanvas-title text-light h5 text-decoration-none" id="offcanvasExampleLabel" href="/">{{ current_site.site_name|default:"Project Makefile" }}</a>
    <button type="button" class="btn-close bg-light" data-bs-dismiss="offcanvas" aria-label="Close"></button>
  </div>
  <div class="offcanvas-body bg-dark">
    {% wagtail_site as current_site %}
    <ul class="navbar-nav justify-content-end flex-grow-1 pe-3">
      <li class="nav-item">
        <a class="nav-link text-light active" aria-current="page" href="/">Home</a>
      </li>
      {% for child in current_site.root_page.get_children %}
      <li class="nav-item">
        <a class="nav-link text-light" href="{{ child.url }}">{{ child }}</a>
      </li>
      {% endfor %}
      <li class="nav-item" id="{% if request.user.is_authenticated %}theme-toggler-authenticated{% else %}theme-toggler-anonymous{% endif %}">
          <span class="nav-link text-light" data-bs-toggle="tooltip" title="Toggle dark mode">
              <i class="fas fa-circle-half-stroke"></i>
          </span>
      </li>
      <div data-component="UserMenu" data-text-color="light" data-is-authenticated="{{ request.user.is_authenticated }}" data-is-superuser="{{ request.user.is_superuser }}"></div>
    </ul>
  </div>
</div>
endef

define HTML_HEADER
{% load wagtailcore_tags %}
{% wagtail_site as current_site %}
<div class="app-header">
    <div class="container py-4 app-navbar">
        <nav class="navbar navbar-transparent navbar-padded navbar-expand-md">
            <a class="navbar-brand me-auto" href="/">{{ current_site.site_name|default:"Project Makefile" }}</a>
            <button class="navbar-toggler"
                    type="button"
                    data-bs-toggle="offcanvas"
                    data-bs-target="#offcanvasExample"
                    aria-controls="offcanvasExample"
                    aria-expanded="false"
                    aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="d-none d-md-block">
                <ul class="navbar-nav">
                    <li class="nav-item">
                        <a id="home-nav"
                           class="nav-link {% if request.path == '/' %}active{% endif %}"
                           aria-current="page"
                           href="/">Home</a>
                    </li>
                    {% for child in current_site.root_page.get_children %}
                        {% if child.show_in_menus %}
			                <li class="nav-item">
                                <a class="nav-link {% if request.path == child.url %}active{% endif %}" aria-current="page"
                                    href="{{ child.url }}">{{ child }}</a>
                            </li>
                        {% endif %}
                    {% endfor %}
                    <div data-component="UserMenu"
                         data-is-authenticated="{{ request.user.is_authenticated }}"
                         data-is-superuser="{{ request.user.is_superuser }}"></div>
                    <li class="nav-item" id="{% if request.user.is_authenticated %}theme-toggler-authenticated{% else %}theme-toggler-anonymous{% endif %}">
                        <span class="nav-link" data-bs-toggle="tooltip" title="Toggle dark mode">
                            <i class="fas fa-circle-half-stroke"></i>
                        </span>
                    </li>
                </ul>
            </div>
        </nav>
    </div>
</div>
endef 

define COMPONENT_ERROR
import { Component } from 'react';
import PropTypes from 'prop-types';

class ErrorBoundary extends Component {
  constructor (props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError () {
    return { hasError: true };
  }

  componentDidCatch (error, info) {
    const { onError } = this.props;
    console.error(error);
    onError && onError(error, info);
  }

  render () {
    const { children = null } = this.props;
    const { hasError } = this.state;

    return hasError ? null : children;
  }
}

ErrorBoundary.propTypes = {
  onError: PropTypes.func,
  children: PropTypes.node,
};

export default ErrorBoundary;
endef

define THEME_BLUE
@import "~bootstrap/scss/bootstrap.scss";

[data-bs-theme="blue"] {
  --bs-body-color: var(--bs-white);
  --bs-body-color-rgb: #{to-rgb($$white)};
  --bs-body-bg: var(--bs-blue);
  --bs-body-bg-rgb: #{to-rgb($$blue)};
  --bs-tertiary-bg: #{$$blue-600};

  .dropdown-menu {
    --bs-dropdown-bg: #{color-mix($$blue-500, $$blue-600)};
    --bs-dropdown-link-active-bg: #{$$blue-700};
  }

  .btn-secondary {
    --bs-btn-bg: #{color-mix($gray-600, $blue-400, .5)};
    --bs-btn-border-color: #{rgba($$white, .25)};
    --bs-btn-hover-bg: #{color-adjust(color-mix($gray-600, $blue-400, .5), 5%)};
    --bs-btn-hover-border-color: #{rgba($$white, .25)};
    --bs-btn-active-bg: #{color-adjust(color-mix($gray-600, $blue-400, .5), 10%)};
    --bs-btn-active-border-color: #{rgba($$white, .5)};
    --bs-btn-focus-border-color: #{rgba($$white, .5)};

    // --bs-btn-focus-box-shadow: 0 0 0 .25rem rgba(255, 255, 255, 20%);
  }
}
endef

define SITEUSER_MODEL
from django.db import models
from django.contrib.auth.models import AbstractUser, Group, Permission
from django.conf import settings

class User(AbstractUser):
    groups = models.ManyToManyField(Group, related_name='siteuser_set', blank=True)
    user_permissions = models.ManyToManyField(
        Permission, related_name='siteuser_set', blank=True
    )
    
    user_theme_preference = models.CharField(max_length=10, choices=settings.THEMES, default='light')
endef

define SETTINGS_THEMES
THEMES = [
    ('light', 'Light Theme'),
    ('dark', 'Dark Theme'),
]
endef

define SITEUSER_ADMIN
from django.contrib.auth.admin import UserAdmin
from django.contrib import admin

from .models import User


admin.site.register(User, UserAdmin)
endef

define THEME_TOGGLER
document.addEventListener('DOMContentLoaded', function () {
    const rootElement = document.documentElement;

    // Theme toggle for anonymous users and authenticated users
    const anonThemeToggle = document.getElementById('theme-toggler-anonymous');
    const authThemeToggle = document.getElementById('theme-toggler-authenticated');

    if (authThemeToggle) {
        localStorage.removeItem('data-bs-theme');
    }

    // Get the theme preference from local storage
    const anonSavedTheme = localStorage.getItem('data-bs-theme');

    // Set the initial theme based on the saved preference or default to light for anonymous users
    if (anonSavedTheme) {
        rootElement.setAttribute('data-bs-theme', anonSavedTheme);
    }

    // Toggle the theme and save the preference on label click for anonymous users
    if (anonThemeToggle) {
        anonThemeToggle.addEventListener('click', function () {
            const currentTheme = rootElement.getAttribute('data-bs-theme') || 'light';
            const newTheme = currentTheme === 'light' ? 'dark' : 'light';

            rootElement.setAttribute('data-bs-theme', newTheme);
            localStorage.setItem('data-bs-theme', newTheme);
        });
    }

    // Check if authThemeToggle exists before adding the event listener
    if (authThemeToggle) {
        // Get the CSRF token from the Django template
        const csrfToken = document.querySelector('[name=csrfmiddlewaretoken]').value;

        // Toggle the theme and save the preference on label click for authenticated users
        authThemeToggle.addEventListener('click', function () {
            const currentTheme = rootElement.getAttribute('data-bs-theme') || 'light';
            const newTheme = currentTheme === 'light' ? 'dark' : 'light';

            // Update the theme on the server for authenticated users
            fetch('/user/update_theme_preference/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': csrfToken, // Include the CSRF token in the headers
                },
                body: JSON.stringify({ theme: newTheme }),
            })
            .then(response => response.json())
            .then(data => {
                // Update the theme on the client side for authenticated users
                rootElement.setAttribute('data-bs-theme', newTheme);
            })
            .catch(error => {
                console.error('Error updating theme preference:', error);
            });
        });
    }
});
endef

# ------------------------------------------------------------------------------  
# Export variables
# ------------------------------------------------------------------------------  

export ALLAUTH_LAYOUT_BASE
export AUTHENTICATION_BACKENDS
export BABELRC
export BACKEND_URLS
export BASE_TEMPLATE
export BLOCK_CAROUSEL
export BLOCK_MARKETING
export COMPONENT_CLOCK
export COMPONENT_ERROR
export COMPONENT_USER_MENU
export CONTACT_PAGE_MODEL
export CONTACT_PAGE_TEMPLATE
export CONTACT_PAGE_LANDING
export ESLINTRC
export FAVICON_TEMPLATE
export FRONTEND_APP
export FRONTEND_APP_CONFIG
export FRONTEND_COMPONENTS
export FRONTEND_STYLES
export GIT_IGNORE
export HOME_PAGE_MODEL
export HOME_PAGE_TEMPLATE
export HTML_FOOTER
export HTML_HEADER
export HTML_OFFCANVAS
export INTERNAL_IPS
export JENKINS_FILE
export PRIVACY_PAGE_MODEL
export REACT_PORTAL
export REST_FRAMEWORK
export REACT_CONTEXT_INDEX
export REACT_CONTEXT_USER_PROVIDER
export PRIVACY_PAGE_MODEL
export PRIVACY_PAGE_TEMPLATE
export SETTINGS_THEMES
export SITEUSER_MODEL
export SITEUSER_ADMIN
export SITEUSER_URLS
export SITEUSER_VIEW
export SITEUSER_TEMPLATE
export THEME_BLUE
export THEME_TOGGLER
export WEBPACK_CONFIG_JS
export WEBPACK_INDEX_JS
export WEBPACK_INDEX_HTML

# ------------------------------------------------------------------------------  
# Rules
# ------------------------------------------------------------------------------  

export-base-default:
	@echo "$$BASE_TEMPLATE"

export-home-default:
	@echo "$$HOME_PAGE_TEMPLATE"

export-header-default:
	@echo "$$HTML_HEADER"

eb-check-env-default:  # https://stackoverflow.com/a/4731504/185820
ifndef ENV_NAME
	$(error ENV_NAME is undefined)
endif
ifndef INSTANCE_TYPE
	$(error INSTANCE_TYPE is undefined)
endif
ifndef LB_TYPE
	$(error LB_TYPE is undefined)
endif
ifndef SSH_KEY
	$(error SSH_KEY is undefined)
endif
ifndef VPC_ID
	$(error VPC_ID is undefined)
endif
ifndef VPC_SG
	$(error VPC_SG is undefined)
endif
ifndef VPC_SUBNET_EC2
	$(error VPC_SUBNET_EC2 is undefined)
endif
ifndef VPC_SUBNET_ELB
	$(error VPC_SUBNET_ELB is undefined)
endif

eb-create-default: eb-check-env
	eb create $(ENV_NAME) \
         -i $(INSTANCE_TYPE) \
         -k $(SSH_KEY) \
         -p $(PLATFORM) \
         --elb-type $(LB_TYPE) \
         --vpc \
         --vpc.id $(VPC_ID) \
         --vpc.elbpublic \
         --vpc.ec2subnets $(VPC_SUBNET_EC2) \
         --vpc.elbsubnets $(VPC_SUBNET_ELB) \
         --vpc.publicip \
         --vpc.securitygroups $(VPC_SG)

eb-deploy-default:
	eb deploy

eb-restart-default:
	systemctl restart web

eb-init-default:
	eb init

eb-list-platforms:
	aws elasticbeanstalk list-platform-versions

npm-init-default:
	npm init -y
	-git add package.json

npm-build-default:
	npm run build

npm-install-default:
	npm install
	-git add package-lock.json

npm-clean-default:
	rm -rvf node_modules/
	rm -vf package-lock.json
	rm -rvf dist/

npm-serve-default:
	npm run start

wagtail-contactpage-default:
	python manage.py startapp contactpage
	@echo "$$CONTACT_PAGE_MODEL" > contactpage/models.py
	-mkdir -vp contactpage/templates/contactpage/
	@echo "$$CONTACT_PAGE_TEMPLATE" > contactpage/templates/contactpage/contact_page.html
	@echo "$$CONTACT_PAGE_LANDING" > contactpage/templates/contactpage/contact_page_landing.html
	@echo "INSTALLED_APPS.append('contactpage')" >> $(SETTINGS)
	python manage.py makemigrations contactpage
	@echo "CRISPY_TEMPLATE_PACK = 'bootstrap5'" >> $(SETTINGS)
	@echo "CRISPY_ALLOWED_TEMPLATE_PACKS = 'bootstrap5'" >> $(SETTINGS)
	-git add contactpage/

django-secret-default:
	python -c "from secrets import token_urlsafe; print(token_urlsafe(50))"

django-siteuser-default:
	python manage.py startapp siteuser
	@echo "$$SITEUSER_MODEL" > siteuser/models.py
	@echo "$$SITEUSER_ADMIN" > siteuser/admin.py
	@echo "$$SITEUSER_VIEW" > siteuser/views.py
	@echo "$$SITEUSER_URLS" > siteuser/urls.py
	-mkdir -v siteuser/templates/
	-mkdir -vp siteuser/management/commands
	@echo "$$SITEUSER_TEMPLATE" > siteuser/templates/profile.html
	@echo "INSTALLED_APPS.append('siteuser')" >> $(SETTINGS)
	@echo "AUTH_USER_MODEL = 'siteuser.User'" >> $(SETTINGS)
	python manage.py makemigrations siteuser
	-git add siteuser/

django-graph-default:
	python manage.py graph_models -a -o $(PROJECT_NAME).png

django-show-urls-default:
	python manage.py show_urls

django-loaddata-default:
	python manage.py loaddata

django-migrate-default:
	python manage.py migrate

django-migrations-default:
	python manage.py makemigrations

django-migrations-show-default:
	python manage.py showmigrations

django-serve-default:
	cd frontend; npm run watch &
	python manage.py runserver 0.0.0.0:8000

django-settings-default:
	echo "# $(PROJECT_NAME)" >> $(SETTINGS)
	echo "ALLOWED_HOSTS = ['*']" >> $(SETTINGS)
	echo "import dj_database_url, os" >> $(SETTINGS)
	echo "DATABASE_URL = os.environ.get('DATABASE_URL', \
         'postgres://$(DB_USER):$(DB_PASS)@$(DB_HOST):$(DB_PORT)/$(PROJECT_NAME)')" >> $(SETTINGS)
	echo "DATABASES['default'] = dj_database_url.parse(DATABASE_URL)" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('webpack_boilerplate')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('rest_framework')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('rest_framework.authtoken')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('allauth')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('allauth.account')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('allauth.socialaccount')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('wagtailmenus')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('wagtailmarkdown')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('wagtail_modeladmin')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('wagtailseo')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('wagtail_color_panel')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('wagtail.contrib.settings')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('django_extensions')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('debug_toolbar')" >> $(DEV_SETTINGS)
	echo "INSTALLED_APPS.append('crispy_forms')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('crispy_bootstrap5')" >> $(SETTINGS)
	echo "INSTALLED_APPS.append('django_recaptcha')" >> $(SETTINGS)
	echo "MIDDLEWARE.append('allauth.account.middleware.AccountMiddleware')" >> $(SETTINGS)
	echo "MIDDLEWARE.append('debug_toolbar.middleware.DebugToolbarMiddleware')" >> $(DEV_SETTINGS)
	echo "MIDDLEWARE.append('hijack.middleware.HijackUserMiddleware')" >> $(DEV_SETTINGS)
	echo "STATICFILES_DIRS.append(os.path.join(BASE_DIR, 'frontend/build'))" >> $(SETTINGS)
	echo "WEBPACK_LOADER = { 'MANIFEST_FILE': os.path.join(BASE_DIR, 'frontend/build/manifest.json'), }" >> $(SETTINGS)
	echo "$$REST_FRAMEWORK" >> $(SETTINGS)
	echo "$$SETTINGS_THEMES" >> $(SETTINGS)
	echo "$$INTERNAL_IPS" >> $(DEV_SETTINGS)
	echo "LOGIN_REDIRECT_URL = '/'" >> $(SETTINGS)
	echo "DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'" >> $(SETTINGS)
	echo "$$AUTHENTICATION_BACKENDS" >> $(SETTINGS)
	echo "TEMPLATES[0]['OPTIONS']['context_processors'].append('wagtail.contrib.settings.context_processors.settings')" >> $(SETTINGS)
	echo "TEMPLATES[0]['OPTIONS']['context_processors'].append('wagtailmenus.context_processors.wagtailmenus')">> $(SETTINGS)
	echo "SILENCED_SYSTEM_CHECKS = ['django_recaptcha.recaptcha_test_key_error']" >> $(SETTINGS)

django-shell-default:
	python manage.py shell

django-static-default:
	python manage.py collectstatic --noinput

django-su-default:
	DJANGO_SUPERUSER_PASSWORD=admin python manage.py createsuperuser --noinput --username=admin --email=$(PROJECT_EMAIL)

django-test-default:
	python manage.py test

django-user-default:
	python manage.py shell -c "from django.contrib.auth.models import User; \
        User.objects.create_user('user', '', 'user')"

django-url-patterns-default:
	echo "$$BACKEND_URLS" > backend/$(URLS)

django-npm-install-default:
	cd frontend; npm install

django-npm-install-save-default:
	cd frontend; npm install \
        @fortawesome/fontawesome-free \
        @fortawesome/fontawesome-svg-core \
        @fortawesome/free-brands-svg-icons \
        @fortawesome/free-solid-svg-icons \
        @fortawesome/react-fontawesome \
        camelize \
        date-fns \
        history \
        mapbox-gl \
        query-string \
        react-animate-height \
        react-chartjs-2 \
        react-copy-to-clipboard \
        react-date-range \
        react-dom \
        react-dropzone \
        react-hook-form \
        react-image-crop \
        react-map-gl \
        react-modal \
        react-resize-detector \
        react-select \
        react-swipeable \
        snakeize \
        striptags \
        url-join \
        viewport-mercator-project

django-npm-install-save-dev-default:
	cd frontend; npm install \
        eslint-plugin-react \
        eslint-config-standard \
        eslint-config-standard-jsx \
        @babel/core \
        @babel/preset-env \
        @babel/preset-react \
        --save-dev

django-npm-test-default:
	cd frontend; npm run test

django-npm-build-default:
	cd frontend; npm run build

django-open-default:
ifeq ($(UNAME), Linux)
	@echo "Opening on Linux."
	xdg-open http://0.0.0.0:8000
else ifeq ($(UNAME), Darwin)
	@echo "Opening on macOS (Darwin)."
	open http://0.0.0.0:8000
else
	@echo "Unable to open on: $(UNAME)"
endif

favicon-default:
	dd if=/dev/urandom bs=64 count=1 status=none | base64 | convert -size 16x16 -depth 8 -background none -fill white label:@- favicon.png
	convert favicon.png favicon.ico
	-git add favicon.ico
	@rm -v favicon.png

gh-default:
	gh browse

git-ignore-default:
	echo "$$GIT_IGNORE" > .gitignore
	-git add .gitignore
	-git commit -a -m "Add .gitignore"
	-git push

git-branches-default:
	-for i in $(GIT_BRANCHES) ; do \
        git checkout -t $$i ; done

git-commit-default:
	-git commit -a -m $(GIT_COMMIT_MESSAGE)

git-push-default:
	-git push

git-commit-edit-default:
	-git commit -a

git-prune-default:
	git remote update origin --prune

git-set-upstream-default:
	git push --set-upstream origin main

git-commit-empty-default:
	git commit --allow-empty -m "Empty-Commit"

lint-black-default:
	-black *.py
	-black backend/*.py
	-black backend/*/*.py
	-git commit -a -m "A one time black event"

lint-djlint-default:
	-djlint --reformat *.html
	-djlint --reformat backend/*.html
	-djlint --reformat backend/*/*.html
	-git commit -a -m "A one time djlint event"

lint-flake-default:
	-flake8 *.py
	-flake8 backend/*.py
	-flake8 backend/*/*.py

lint-isort-default:
	-isort *.py
	-isort backend/*.py
	-isort backend/*/*.py
	-git commit -a -m "A one time isort event"

lint-ruff-default:
	-ruff *.py
	-ruff backend/*.py
	-ruff backend/*/*.py
	-git commit -a -m "A one time ruff event"

db-mysql-init-default:
	-mysqladmin -u root drop $(PROJECT_NAME)
	-mysqladmin -u root create $(PROJECT_NAME)

db-pg-init-default:
	-dropdb $(PROJECT_NAME)
	-createdb $(PROJECT_NAME)

pip-freeze-default:
	pip3 freeze | sort > $(TMPDIR)/requirements.txt
	mv -f $(TMPDIR)/requirements.txt .
	-git add requirements.txt

pip-init-default:
	touch requirements.txt
	-git add requirements.txt

pip-install-default:
	$(MAKE) pip-upgrade
	pip3 install wheel
	pip3 install -r requirements.txt

pip-install-dev-default:
	pip3 install -r requirements-dev.txt

pip-install-test-default:
	pip3 install -r requirements-test.txt

pip-install-upgrade-default:
	cat requirements.txt | awk -F \= '{print $$1}' > $(TMPDIR)/requirements.txt
	mv -f $(TMPDIR)/requirements.txt .
	pip3 install -U -r requirements.txt
	pip3 freeze | sort > $(TMPDIR)/requirements.txt
	mv -f $(TMPDIR)/requirements.txt .

pip-upgrade-default:
	pip3 install -U pip

pip-uninstall-default:
	pip3 freeze | xargs pip3 uninstall -y

python-setup-sdist-default:
	python3 setup.py sdist --format=zip

readme-init-default:
	@echo "$(PROJECT_NAME)" > README.rst
	@echo "================================================================================" >> README.rst
	-@git add README.rst
	-git commit -a -m "Add readme"

readme-edit-default:
	vi README.rst

readme-open-default:
	open README.pdf

readme-build-default:
	rst2pdf README.rst

sphinx-init-default:
	$(MAKE) sphinx-install
	sphinx-quickstart -q -p $(PROJECT_NAME) -a $(USER) -v 0.0.1 $(RANDIR)
	mv $(RANDIR)/* .
	rmdir $(RANDIR)

sphinx-install-default:
	echo "Sphinx\n" > requirements.txt
	@$(MAKE) pip-install
	@$(MAKE) pip-freeze
	-git add requirements.txt

sphinx-build-default:
	sphinx-build -b html -d _build/doctrees . _build/html

sphinx-build-pdf-default:
	sphinx-build -b rinoh . _build/rinoh

sphinx-serve-default:
	cd _build/html;python3 -m http.server

wagtail-privacy-default:
	python manage.py startapp privacy
	@echo "$$PRIVACY_PAGE_MODEL" > privacy/models.py
	mkdir privacy/templates
	@echo "$$PRIVACY_PAGE_TEMPLATE" > privacy/templates/privacy_page.html
	@echo "INSTALLED_APPS.append('privacy')" >> $(SETTINGS)
	python manage.py makemigrations privacy
	-git add privacy/

wagtail-clean-default:
	-rm -vf .dockerignore
	-rm -vf Dockerfile
	-rm -vf manage.py
	-rm -vf requirements.txt
	-rm -rvf home/
	-rm -rvf search/
	-rm -rvf backend/
	-rm -rvf siteuser/
	-rm -rvf privacy/
	-rm -rvf frontend/
	-rm -rvf contactpage/
	-rm -vf README.rst

wagtail-init-default: db-init wagtail-install
	wagtail start backend .
	$(MAKE) pip-freeze
	export SETTINGS=backend/settings/base.py DEV_SETTINGS=backend/settings/dev.py; $(MAKE) django-settings
	export URLS=urls.py; $(MAKE) django-url-patterns
	-git add backend
	-git add requirements.txt
	-git add manage.py
	-git add Dockerfile
	-git add .dockerignore
	@echo "$$HOME_PAGE_MODEL" > home/models.py
	export SETTINGS=backend/settings/base.py; $(MAKE) django-siteuser
	export SETTINGS=backend/settings/base.py; $(MAKE) wagtail-privacy
	export SETTINGS=backend/settings/base.py; $(MAKE) wagtail-contactpage
	@$(MAKE) django-migrations
	-git add home
	-git add search
	@$(MAKE) django-migrate
	@$(MAKE) su
	@echo "$$BASE_TEMPLATE" > backend/templates/base.html
	@echo "$$FAVICON_TEMPLATE" > backend/templates/favicon.html
	@echo "$$HTML_HEADER" > backend/templates/header.html
	@echo "$$HTML_FOOTER" > backend/templates/footer.html
	@echo "$$HTML_OFFCANVAS" > backend/templates/offcanvas.html
	mkdir -p backend/templates/allauth/layouts
	@echo "$$ALLAUTH_LAYOUT_BASE" > backend/templates/allauth/layouts/base.html
	-git add backend/templates/
	@echo "$$HOME_PAGE_TEMPLATE" > home/templates/home/home_page.html
	mkdir -p home/templates/blocks
	@echo "$$BLOCK_MARKETING" > home/templates/blocks/marketing_block.html
	@echo "$$BLOCK_CAROUSEL" > home/templates/blocks/carousel_block.html
	-git add home/templates/blocks
	python manage.py webpack_init --no-input
	@echo "$$COMPONENT_CLOCK" > frontend/src/components/Clock.js
	@echo "$$COMPONENT_ERROR" > frontend/src/components/ErrorBoundary.js
	mkdir frontend/src/context
	mkdir frontend/src/images
	@echo "$$REACT_CONTEXT_INDEX" > frontend/src/context/index.js
	@echo "$$REACT_CONTEXT_USER_PROVIDER" > frontend/src/context/UserContextProvider.js
	@echo "$$COMPONENT_USER_MENU" > frontend/src/components/UserMenu.js
	@echo "$$FRONTEND_APP" > frontend/src/application/app.js
	@echo "$$FRONTEND_APP_CONFIG" > frontend/src/application/config.js
	@echo "$$FRONTEND_COMPONENTS" > frontend/src/components/index.js
	@echo "$$FRONTEND_STYLES" > frontend/src/styles/index.scss
	@echo "$$REACT_PORTAL" > frontend/src/dataComponents.js
	@echo "$$BABELRC" > frontend/.babelrc
	@echo "$$ESLINTRC" > frontend/.eslintrc
	@echo "$$THEME_BLUE" > frontend/src/styles/theme-blue.scss
	@-mkdir -v frontend/src/utils/
	@echo "$$THEME_TOGGLER" > frontend/src/utils/themeToggler.js
	-git add frontend/src/utils/
	-git add home
	-git add frontend
	-git commit -a -m "Add frontend"
	@$(MAKE) django-npm-install
	@$(MAKE) django-npm-install-save
	@$(MAKE) django-npm-install-save-dev
	@$(MAKE) cp
	@$(MAKE) lint-isort
	@$(MAKE) lint-black
	@$(MAKE) cp
	@$(MAKE) lint-flake
	@$(MAKE) readme
	@$(MAKE) gitignore
	@$(MAKE) serve

wagtail-install-default:
	pip3 install \
        Faker \
		boto3 \
        crispy-bootstrap5 \
        djangorestframework \
        django-allauth \
        django-after-response \
        django-ckeditor \
        django-countries \
        django-cors-headers \
        django-crispy-forms \
        django-debug-toolbar \
        django-extensions \
        django-hijack \
        django-honeypot \
        django-imagekit \
        django-import-export \
        django-ipware \
	 	django-multiselectfield \
        django-phonenumber-field \
        django-recurrence \
        django-recaptcha \
        django-registration \
        django-rest-auth \
        django-richtextfield \
        django-social-share \
        django-storages \
        django-tables2 \
        django-timezone-field \
        dj-database-url \
        dj-stripe \
        dj-rest-auth \
		enmerkar \
        icalendar \
        mailchimp-marketing \
        mailchimp-transactional \
        phonenumbers \
        psycopg2-binary \
        python-webpack-boilerplate \
		reportlab \
        texttable \
        wagtail \
        wagtailmenus \
        wagtail-color-panel \
        wagtail-django-recaptcha \
        wagtail-markdown \
        wagtail_modeladmin \
        wagtail-seo \
        whitenoise \
		xhtml2pdf 

help-default:
	@for makefile in $(MAKEFILE_LIST); do \
        $(MAKE) -pRrq -f $$makefile : 2>/dev/null \
            | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' \
            | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' \
            | xargs | tr ' ' '\n' \
            | awk '{printf "%s\n", $$0}' ; done | less # http://stackoverflow.com/a/26339924 Given a base.mk, Makefile and project.mk, and base.mk and project.mk included from Makefile, print target names from all makefiles.

usage-default:
	@echo "Project Makefile 🤷"
	@echo "Usage: make [options] [target] ..."
	@echo "Examples:"
	@echo "   make help    Print all targets"
	@echo "   make usage   Print this message"

jenkins-init-default:
	@echo "$$JENKINS_FILE" > Jenkinsfile

webpack-init-default: npm-init
	@echo "$$WEBPACK_CONFIG_JS" > webpack.config.js
	-git add webpack.config.js
	npm install --save-dev webpack webpack-cli
	-mkdir -v src/
	@echo "$$WEBPACK_INDEX_JS" > src/index.js
	-git add src/index.js
	@echo "$$WEBPACK_INDEX_HTML" > index.html
	-git add index.html

make-default:
	-git add Makefile
	-git commit -a -m "Add/update project-makefile files"
	-git push

python-serve-default:
	@echo "\n\tServing HTTP on http://0.0.0.0:8000\n"
	python3 -m http.server

rand-default:
	@openssl rand -base64 12 | sed 's/\///g'

review-default:
ifeq ($(UNAME), Darwin)
	$(REVIEW_EDITOR) `find backend/ -name \*.py` `find backend/ -name \*.html` `find frontend/ -name \*.js` `find frontend/ -name \*.js`
else
	@echo "Unsupported"
endif

project-mk-default:
	touch project.mk
	-git add project.mk

# ------------------------------------------------------------------------------  
# More rules
# ------------------------------------------------------------------------------  

build-default: sphinx-build
b-default: build 
black-default: lint-black
c-default: clean
ce-default: git-commit-edit-push
clean-default: wagtail-clean
cp-default: git-commit-push
d-default: deploy
deploy-default: eb-deploy
db-init-default: db-pg-init
django-clean-default: wagtail-clean
django-init-default: wagtail-init
djlint-default: lint-djlint
edit-default: readme-edit
e-default: edit
empty-default: git-commit-empty
freeze-default: pip-freeze
h-default: help
init-default: wagtail-init
install-default: pip-install
install-dev-default: pip-install-dev
install-test-default: pip-install-test
i-default: install
migrate-default: django-migrate
migrations-default: django-migrations
migrations-show-default: django-migrations-show
mk-default: project-mk
git-commit-edit-push-default: git-commit-edit git-push
git-commit-push-default: git-commit git-push
gitignore-default: git-ignore
open-default: django-open
o-default: open
p-default: git-push
pg-init-default: db-pg-init
readme-default: readme-init
restart-default: eb-restart
secret-default: django-secret
serve-default: django-serve
shell-default: django-shell
show-urls-default: django-show-urls
su-default: django-su
s-default: serve
static-default: django-static
sdist-default: python-setup-sdist
test-default: django-test
u-default: usage
urls-default: django-show-urls
webpack-default: webpack-init

# --------------------------------------------------------------------------------
# Overrides
# --------------------------------------------------------------------------------

%: %-default  # https://stackoverflow.com/a/49804748
	@ true
