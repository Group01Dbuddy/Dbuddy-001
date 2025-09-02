from fastapi import FastAPI
from pydantic import BaseModel
import base64
import numpy as np
from io import BytesIO
from PIL import Image
import tensorflow as tf
import json
from tensorflow.keras.applications.efficientnet import preprocess_input

# ===============================
# Load model and data
# ===============================
app = FastAPI()

MODEL_PATH = "assets/ml_parts/food_b7_final_fp16.tflite"
CLASS_NAMES_PATH = "assets/ml_parts/class_names.json"
NUTRITION_PATH = "assets/ml_parts/food_calories.json"

interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

with open(CLASS_NAMES_PATH, 'r') as f:
    class_labels = json.load(f)

with open(NUTRITION_PATH, 'r') as f:
    nutrition_data = json.load(f)

# ===============================
# Request body schema
# ===============================
class ImageRequest(BaseModel):
    image: str       # base64 image string
    weight: int = 100  # optional, default 100g

# ===============================
# Prediction endpoint
# ===============================
@app.post("/predict")
def predict(request: ImageRequest):
    # Decode image
    img_bytes = base64.b64decode(request.image)
    img = Image.open(BytesIO(img_bytes)).convert("RGB")
    img = img.resize((224, 224))
    img_array = np.array(img, dtype=np.float32)
    img_array = np.expand_dims(img_array, axis=0)
    
    # Preprocess for EfficientNetB7
    img_array = preprocess_input(img_array)

    # TFLite inference
    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()
    preds = interpreter.get_tensor(output_details[0]['index'])[0]

    # Get predicted class
    idx = int(np.argmax(preds))
    confidence = float(preds[idx])
    predicted_class = class_labels[idx]

    # Lookup nutrition
    norm_class = predicted_class.replace(" ", "_")
    info = nutrition_data.get(predicted_class) or nutrition_data.get(norm_class)

    result = {
        "food": predicted_class,
        "confidence": round(confidence, 4)
    }

    if info:
        factor = request.weight / 100.0
        result.update({
            "weight_g": request.weight,
            "calories": round(info["calories_per_100g"] * factor, 2),
            "carbs_g": round(info["carbs"] * factor, 2),
            "protein_g": round(info["protein"] * factor, 2),
            "fat_g": round(info["fat"] * factor, 2),
        })
    else:
        result["message"] = "No nutrition data available"

    # Also return full probability scores if needed
    all_scores = {class_labels[i]: float(preds[i]) for i in range(len(class_labels))}
    result["all_scores"] = all_scores

    return result

