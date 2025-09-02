from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
import json
from PIL import Image, ExifTags
import io
import base64
from tensorflow.keras.preprocessing.image import img_to_array
from tensorflow.keras.applications.efficientnet import preprocess_input

app = Flask(__name__)

# Global variables for model and data
interpreter = None
class_names = None
nutrition_data = None

def load_model_and_data():
    global interpreter, class_names, nutrition_data

    # Load TFLite model
    interpreter = tf.lite.Interpreter(model_path="assets/ml_parts/food_b7_final_fp16.tflite")
    interpreter.allocate_tensors()

    # Load class names
    with open("assets/ml_parts/class_names.json", 'r') as f:
        class_names = json.load(f)

    # Load nutrition data
    with open("assets/ml_parts/food_calories.json", 'r') as f:
        nutrition_data = json.load(f)

    print(f"Model loaded with {len(class_names)} classes")

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Get image from request
        image_data = request.json['image']
        image_bytes = base64.b64decode(image_data)
        image = Image.open(io.BytesIO(image_bytes))

        # Handle EXIF orientation
        try:
            exif = image._getexif()
            if exif is not None:
                for tag, value in exif.items():
                    if tag in ExifTags.TAGS and ExifTags.TAGS[tag] == 'Orientation':
                        if value == 3:
                            image = image.rotate(180)
                        elif value == 6:
                            image = image.rotate(270)
                        elif value == 8:
                            image = image.rotate(90)
                        break
        except:
            pass

        # Preprocess image (same as Colab)
        image = image.resize((224, 224))
        img_array = img_to_array(image)
        img_array = preprocess_input(img_array).astype(np.float32)

        # Add batch dimension
        img_array = np.expand_dims(img_array, axis=0)

        # Debug prints
        print("Image shape after resize:", image.size)
        print("Img array shape:", img_array.shape)
        print("Img array dtype:", img_array.dtype)
        print("First few values:", img_array[0, 0, :5])
        print("Input details:", interpreter.get_input_details())

        # Run inference
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        interpreter.set_tensor(input_details[0]['index'], img_array)
        interpreter.invoke()
        predictions = interpreter.get_tensor(output_details[0]['index'])

        # Get prediction results
        scores = predictions[0]
        predicted_index = np.argmax(scores)
        predicted_class = class_names[predicted_index]
        confidence = float(scores[predicted_index])

        # Get nutrition info
        nutrition_info = nutrition_data.get(predicted_class, {})

        # Return all scores for debugging
        all_scores = {class_names[i]: float(scores[i]) for i in range(len(class_names))}

        return jsonify({
            'predicted_class': predicted_class,
            'confidence': confidence,
            'nutrition_info': nutrition_info,
            'all_scores': all_scores
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    load_model_and_data()
    app.run(host='0.0.0.0', port=5000, debug=True)
