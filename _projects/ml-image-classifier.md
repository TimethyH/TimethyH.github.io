---
layout: project
title: "Machine Learning Image Classifier"
subtitle: "An ML model that classifies images into categories"
category: year1
thumbnail: /assets/img/background.jpg
technologies: 
  - Python
  - TensorFlow
  - Keras
  - scikit-learn
summary: "A convolutional neural network that classifies images with 95% accuracy."
github: https://github.com/yourusername/image-classifier
date: 2025-03-20
---

## Project Overview

This project implements a convolutional neural network (CNN) for image classification. The model was trained on a dataset of 10,000 images across 10 categories and achieves an accuracy of 95% on the test set.

## Technical Details

The model architecture consists of:

- 3 convolutional layers with max pooling
- 2 fully connected layers
- Dropout for regularization
- Softmax activation for classification

## Data Processing

The training data underwent several preprocessing steps:

- Normalization
- Data augmentation (rotation, zoom, flip)
- Train/validation/test split (70%/15%/15%)

## Results

The final model achieved the following metrics:

- Training accuracy: 97%
- Validation accuracy: 95%
- Test accuracy: 95%
- F1-score: 0.94

## Sample Predictions

*Examples of correctly classified images*

## Future Work

- Implement transfer learning with pre-trained models
- Create a web interface for real-time predictions
- Extend the model to handle video classification